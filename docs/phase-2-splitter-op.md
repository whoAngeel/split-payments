# Phase 2: Splitter with real Open Payments

Goal: The Splitter orchestrates a real split payment via the Open Payments Go SDK using the Interledger testnet.

## Prerequisites

- [ ] A wallet on https://wallet.interledger-test.dev/ with a registered Ed25519 key pair
- [ ] The private key file (PEM) and its `keyId` from the testnet
- [ ] At least one recipient wallet address (can be the same account, different wallet)

## Steps

### 2.1 — Environment config

1. Create `backend/.env` with:

```
WALLET_ADDRESS_URL=https://ilp.interledger-test.dev/YOUR_USER
PRIVATE_KEY_PATH=./dev.key
KEY_ID=your-key-id-from-testnet
```

2. Add `github.com/joho/godotenv`:
   ```bash
   go get github.com/joho/godotenv
   ```

3. Load `.env` at the top of `cmd/splitter/main.go`:
   ```go
   import "github.com/joho/godotenv"
   // in main():
   godotenv.Load()
   ```

### 2.2 — Open Payments client wrapper

Create `internal/splitter/service/payment.go` with a struct that:

1. Holds an `*op.AuthenticatedClient` from `github.com/interledger/open-payments-go`
2. Constructor `NewPaymentService(walletAddr, privateKey, keyId string)` calls `op.NewAuthenticatedClient(...)`
3. Imports needed:
   ```go
   op "github.com/interledger/open-payments-go"
   as "github.com/interledger/open-payments-go/generated/authserver"
   rs "github.com/interledger/open-payments-go/generated/resourceserver"
   ```

**Reference:** `go doc github.com/interledger/open-payments-go NewAuthenticatedClient`

### 2.3 — Resolve wallet addresses

Add a method `GetWalletAddresses(ctx, senderUrl string, shares []ShareItem)` that:

1. Calls `client.WalletAddress.Get(ctx, op.WalletAddressGetParams{URL: senderUrl})` for the sender
2. Calls `client.WalletAddress.Get(ctx, ...)` for EACH share wallet URL
3. Returns a struct with resolved wallet info (authServer, resourceServer, assetCode, assetScale)

**Reference:** `go doc github.com/interledger/open-payments-go WalletAddressService.Get`

### 2.4 — Create incoming payments

Add a method `CreateIncomingPayments(ctx, shares, wallets)` that for EACH share:

1. Requests an incoming-payment grant from the recipient's authServer:
   ```go
   incomingAccess := as.AccessIncoming{
       Type:    as.IncomingPayment,
       Actions: []as.AccessIncomingActions{as.AccessIncomingActionsCreate},
   }
   accessItem := as.AccessItem{}
   accessItem.FromAccessIncoming(incomingAccess)
   accessToken := as.AccessTokenRequest{Access: []as.AccessItem{accessItem}}
   grant, err := client.Grant.Request(ctx, op.GrantRequestParams{
       URL:         *wallet.AuthServer,
       RequestBody: as.GrantRequestWithAccessToken{AccessToken: accessToken},
   })
   ```
   **Don't forget:** The `GrantRequestWithAccessToken` needs the `AccessToken` field (not `AccessTokenRequest` directly typed — check the generated type). You'll need a wrapper struct:
   ```go
   type accessTokenWrapper struct {
       Access as.Access `json:"access"`
   }
   ```

2. Creates the incoming payment:
   ```go
   incoming, err := client.IncomingPayment.Create(ctx, op.IncomingPaymentCreateParams{
       BaseURL:     *wallet.ResourceServer,
       AccessToken: grant.AccessToken.Value,
       Payload: rs.CreateIncomingPaymentJSONBody{
           WalletAddressSchema: *wallet.Id,
           IncomingAmount: &rs.Amount{
               Value:      share.Amount,
               AssetCode:  wallet.AssetCode,
               AssetScale: wallet.AssetScale,
           },
       },
   })
   ```
   **Note:** `AssetCode` and `AssetScale` are pointers (`*string`, `*int`). Use `&`.

**Reference:** https://openpayments.dev/es/guides/split-payments/ — Steps 2 and 3

### 2.5 — Create quotes

Add a method `CreateQuotes(ctx, senderWallet, incomingPayments)` that for EACH incoming payment:

1. Requests a quote grant from the SENDER's authServer (type: `as.Quote`, actions: `[as.Create]`)
2. Creates a quote:
   ```go
   quote, err := client.Quote.Create(ctx, op.QuoteCreateParams{
       BaseURL:     *senderWallet.ResourceServer,
       AccessToken: quoteGrant.AccessToken.Value,
       Payload: rs.CreateQuoteJSONBody0{
           Method:              "ilp",
           WalletAddressSchema: *senderWallet.Id,
           Receiver:            *incomingPayment.Id,
       },
   })
   ```
3. The quote response has `DebitAmount` and `ReceiveAmount` — keep both

**Reference:** https://openpayments.dev/es/guides/split-payments/ — Steps 4 and 5

### 2.6 — Request outgoing payment grant (interactive)

Add a method `RequestOutgoingPaymentGrant(ctx, senderWallet, quotes)` that:

1. Sums all quote `debitAmount` values into a single total
2. Requests an interactive grant with redirect:
   ```go
   limits := as.LimitsOutgoing{}
   limits.FromLimitsOutgoing1(as.LimitsOutgoing1{
       DebitAmount: as.Amount{
           Value:      totalDebit,
           AssetCode:  "USD",
           AssetScale: 2,
       },
   })
   outgoingAccess := as.AccessOutgoing{
       Type:       as.OutgoingPayment,
       Actions:    []as.AccessOutgoingActions{as.AccessOutgoingActionsCreate, as.AccessOutgoingActionsRead},
       Identifier: *senderWallet.Id,
       Limits:     &limits,
   }
   // ...
   interact := &as.InteractRequest{
       Start: []as.InteractRequestStart{as.InteractRequestStartRedirect},
       Finish: &as.InteractRequestFinish{
           Method: as.Redirect,
           Uri:    "http://localhost:4001/split/callback",
           Nonce:  uuid.New().String(),
       },
   }
   ```
3. Returns `{redirectUrl, continueUri, continueToken}`

**Critical:** `LimitsOutgoing` and `LimitsOutgoing1` are generated union types. The pattern is:
- Create `LimitsOutgoing` (the union wrapper)
- Call `.FromLimitsOutgoing1(val)` to set the inner value
- Then use `&limits`

**Reference:** https://openpayments.dev/es/guides/split-payments/ — Step 6

### 2.7 — Callback endpoint

Add a GET endpoint in the handler: `GET /split/callback`

This receives the redirect from the wallet provider after user consent. The query params contain:
- `hash` — a signature you must verify
- `interact_ref` — the reference for continuing the grant

Store the `interact_ref` and continue the grant.

**Reference:** https://openpayments.dev/es/identity/hash-verification/

### 2.8 — Continue grant + create outgoing payments

Add a method `ExecuteOutgoingPayments(ctx, senderWallet, quotes, continueUri, continueToken, interactRef)` that:

1. Continues the grant:
   ```go
   finalizedGrant, err := client.Grant.Continue(ctx, op.GrantContinueParams{
       URL:         continueUri,
       AccessToken: continueToken,
       InteractRef: interactRef,
   })
   ```
2. For EACH quote, creates an outgoing payment:
   ```go
   var payload rs.CreateOutgoingPaymentRequest
   payload.FromCreateOutgoingPaymentWithQuote(rs.CreateOutgoingPaymentWithQuote{
       QuoteId:             *quote.Id,
       WalletAddressSchema: *senderWallet.Id,
   })
   outgoing, err := client.OutgoingPayment.Create(ctx, op.OutgoingPaymentCreateParams{
       BaseURL:     *senderWallet.ResourceServer,
       AccessToken: finalizedGrant.AccessToken.Value,
       Payload:     payload,
   })
   ```

**Reference:** https://openpayments.dev/es/guides/split-payments/ — Steps 9 and 10

### 2.9 — Wire it up in the handler

Update `SplitHandler.Split` to:

1. Create the `PaymentService` (pass to handler constructor)
2. Call methods in sequence: wallet lookup → incoming payments → quotes → outgoing grant → wait for callback → execute
3. Store session state (you'll need a simple in-memory store or map for now)

### 2.10 — Gotchas cheatsheet

| Trap | Fix |
|---|---|
| `AccessTokenRequest` isn't direct type for `GrantRequestWithAccessToken.AccessToken` | Wrap in struct with `Access` field |
| `AssetCode`/`AssetScale` are `*string` / `*int` | Use `&` or helpers like `op.String("USD")` |
| `LimitsOutgoing` is a generated union | Call `.FromLimitsOutgoing1()` to set value |
| `CreateOutgoingPaymentRequest` is a union | Call `.FromCreateOutgoingPaymentWithQuote()` |
| `CreateQuoteJSONBody0` only accepts `Method`, `Receiver`, `WalletAddressSchema` | No debit/receive amount — it's inferred from the incoming payment |
| Grant response fields are pointers | Check `!= nil` before dereferencing |
| Incoming payment grant might need `read-all` action too | Add `as.AccessIncomingActionsReadAll` if listing fails |
