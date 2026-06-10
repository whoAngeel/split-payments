package service

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"sync"

	"github.com/charmbracelet/log"
	"github.com/google/uuid"

	op "github.com/interledger/open-payments-go"
	as "github.com/interledger/open-payments-go/generated/authserver"
	rs "github.com/interledger/open-payments-go/generated/resourceserver"
	was "github.com/interledger/open-payments-go/generated/walletaddressserver"
)

type quoteData struct {
	ID string
}

type sessionData struct {
	ClientNonce   string
	ServerNonce   string
	AuthServerURL string
	ContinueURI   string
	ContinueToken string
	SenderWallet  string
	Quotes        []splitQuote
}

type PaymentService struct {
	client    *op.AuthenticatedClient
	log       *log.Logger
	sessions  map[string]*sessionData
	sessionsMu sync.RWMutex
}

type OutgoingGrantResult struct {
	SessionID     string `json:"session_id"`
	RedirectURL   string `json:"redirect_url"`
	ContinueURI   string `json:"-"`
	ContinueToken string `json:"-"`
}

func NewPaymentService(client *op.AuthenticatedClient, logger *log.Logger) *PaymentService {
	return &PaymentService{
		client:   client,
		log:      logger,
		sessions: make(map[string]*sessionData),
	}
}

func (s *PaymentService) GetWalletInfo(ctx context.Context, walletURL string) (*was.WalletAddress, error) {
	walletAddress, err := s.client.WalletAddress.Get(ctx, op.WalletAddressGetParams{
		URL: walletURL,
	})
	if err != nil {
		return nil, fmt.Errorf("getting wallet address info: %w", err)
	}
	return &walletAddress, nil
}

func (s *PaymentService) CreateIncomingPayment(ctx context.Context, walletURL, amount string) (*rs.IncomingPaymentWithMethods, error) {
	walletAddress, err := s.GetWalletInfo(ctx, walletURL)
	if err != nil {
		return nil, fmt.Errorf("getting wallet address info: %w", err)
	}

	incomingAccess := as.AccessIncoming{
		Type:    as.IncomingPayment,
		Actions: []as.AccessIncomingActions{as.AccessIncomingActionsCreate},
	}
	accessItem := as.AccessItem{}
	if err := accessItem.FromAccessIncoming(incomingAccess); err != nil {
		return nil, fmt.Errorf("creating access item: %w", err)
	}

	accessToken := struct {
		Access as.Access `json:"access"`
	}{
		Access: []as.AccessItem{accessItem},
	}

	grant, err := s.client.Grant.Request(ctx, op.GrantRequestParams{
		URL: *walletAddress.AuthServer,
		RequestBody: as.GrantRequestWithAccessToken{
			AccessToken: accessToken,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("requesting incoming payment grant: %w", err)
	}

	if grant.IsInteractive() {
		return nil, fmt.Errorf("unexpected interactive grant for incoming payment")
	}

	incoming, err := s.client.IncomingPayment.Create(ctx, op.IncomingPaymentCreateParams{
		BaseURL:     *walletAddress.ResourceServer,
		AccessToken: grant.AccessToken.Value,
		Payload: rs.CreateIncomingPaymentJSONBody{
			WalletAddressSchema: *walletAddress.Id,
			IncomingAmount: &rs.Amount{
				Value:      amount,
				AssetCode:  walletAddress.AssetCode,
				AssetScale: walletAddress.AssetScale,
			},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("creating incoming payment: %w", err)
	}

	return &incoming, nil
}

func (s *PaymentService) CreateQuote(ctx context.Context, senderWallet, incomingPaymentID string) (*rs.Quote, error) {
	walletAddress, err := s.GetWalletInfo(ctx, senderWallet)
	if err != nil {
		return nil, fmt.Errorf("getting wallet address info: %w", err)
	}

	quoteAccess := as.AccessQuote{
		Type: as.Quote,
		Actions: []as.AccessQuoteActions{
			as.Create,
			as.Read,
		},
	}
	accessItem := as.AccessItem{}
	if err := accessItem.FromAccessQuote(quoteAccess); err != nil {
		return nil, fmt.Errorf("error creating accessitem: %w", err)
	}
	accessToken := struct {
		Access as.Access `json:"access"`
	}{
		Access: []as.AccessItem{accessItem},
	}

	grant, err := s.client.Grant.Request(ctx, op.GrantRequestParams{
		URL:         *walletAddress.AuthServer,
		RequestBody: as.GrantRequestWithAccessToken{AccessToken: accessToken},
	})
	if err != nil {
		return nil, fmt.Errorf("requesting quote grant: %w", err)
	}

	if grant.IsInteractive() {
		return nil, fmt.Errorf("unexpected interactive grant for quote")
	}

	quote, err := s.client.Quote.Create(ctx, op.QuoteCreateParams{
		BaseURL:     *walletAddress.ResourceServer,
		AccessToken: grant.AccessToken.Value,
		Payload: rs.CreateQuoteJSONBody0{
			Method:              "ilp",
			WalletAddressSchema: *walletAddress.Id,
			Receiver:            incomingPaymentID,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("creating quote: %w", err)
	}

	return &quote, nil

}

func (s *PaymentService) RequestOutgoingPaymentGrant(
	ctx context.Context,
	senderWalletURL, totalDebitAmount string,
) (*OutgoingGrantResult, error) {
	walletAddress, err := s.GetWalletInfo(ctx, senderWalletURL)
	if err != nil {
		return nil, fmt.Errorf("getting sender wallet info: %w", err)
	}

	sessionID := uuid.New().String()
	nonce := uuid.New().String()

	outgoingAccess := as.AccessOutgoing{
		Type: as.OutgoingPayment,
		Actions: []as.AccessOutgoingActions{
			as.AccessOutgoingActionsCreate,
			as.AccessOutgoingActionsRead,
		},
		Identifier: *walletAddress.Id,
	}

	limits := as.LimitsOutgoing{}
	if err := limits.FromLimitsOutgoing1(as.LimitsOutgoing1{
		DebitAmount: as.Amount{
			Value:      totalDebitAmount,
			AssetCode:  walletAddress.AssetCode,
			AssetScale: walletAddress.AssetScale,
		},
	}); err != nil {
		return nil, fmt.Errorf("creating limits: %w", err)
	}
	outgoingAccess.Limits = &limits

	accessItem := as.AccessItem{}
	if err := accessItem.FromAccessOutgoing(outgoingAccess); err != nil {
		return nil, fmt.Errorf("creating access item: %w", err)
	}

	accessToken := struct {
		Access as.Access `json:"access"`
	}{
		Access: []as.AccessItem{accessItem},
	}

	callbackURL := fmt.Sprintf("http://localhost:4001/split/callback?session=%s", sessionID)

	interact := &as.InteractRequest{
		Start: []as.InteractRequestStart{as.InteractRequestStartRedirect},
		Finish: &struct {
			Method as.InteractRequestFinishMethod `json:"method"`
			Nonce  string                         `json:"nonce"`
			Uri    string                         `json:"uri"`
		}{
			Method: as.InteractRequestFinishMethodRedirect,
			Uri:    callbackURL,
			Nonce:  nonce,
		},
	}

	grant, err := s.client.Grant.Request(ctx, op.GrantRequestParams{
		URL: *walletAddress.AuthServer,
		RequestBody: as.GrantRequestWithAccessToken{
			AccessToken: accessToken,
			Interact:    interact,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("requesting outgoing payment grant: %w", err)
	}

	if !grant.IsInteractive() {
		return nil, fmt.Errorf("expected interactive grant for outgoing payment")
	}

	s.sessionsMu.Lock()
	s.sessions[sessionID] = &sessionData{
		ClientNonce:   nonce,
		ServerNonce:   grant.Interact.Finish,
		AuthServerURL: *walletAddress.AuthServer,
		ContinueURI:   grant.Continue.Uri,
		ContinueToken: grant.Continue.AccessToken.Value,
	}
	s.sessionsMu.Unlock()

	return &OutgoingGrantResult{
		SessionID:   sessionID,
		RedirectURL: grant.Interact.Redirect,
	}, nil
}

func (s *PaymentService) HandleCallback(ctx context.Context, sessionID, interactRef, hash string) (*as.AccessToken, error) {
	s.sessionsMu.RLock()
	sd, ok := s.sessions[sessionID]
	s.sessionsMu.RUnlock()
	if !ok {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	base := fmt.Sprintf("%s\n%s\n%s\n%s",
		sd.ClientNonce,
		sd.ServerNonce,
		interactRef,
		sd.AuthServerURL,
	)
	computed := sha256.Sum256([]byte(base))

	received, err := base64.RawStdEncoding.DecodeString(hash)
	if err != nil {
		received, err = base64.StdEncoding.DecodeString(hash)
		if err != nil {
			received, err = base64.RawURLEncoding.DecodeString(hash)
			if err != nil {
				received, err = base64.URLEncoding.DecodeString(hash)
				if err != nil {
					return nil, fmt.Errorf("decoding hash: %w", err)
				}
			}
		}
	}

	if string(computed[:]) != string(received) {
		return nil, fmt.Errorf("hash mismatch")
	}

	grant, err := s.client.Grant.Continue(ctx, op.GrantContinueParams{
		URL:         sd.ContinueURI,
		AccessToken: sd.ContinueToken,
		InteractRef: interactRef,
	})
	if err != nil {
		return nil, fmt.Errorf("continuing grant: %w", err)
	}

	return grant.AccessToken, nil
}

func (s *PaymentService) CreateOutgoingPayment(ctx context.Context, senderWalletURL, quoteID, accessToken string) (*rs.OutgoingPayment, error) {
	walletAddress, err := s.GetWalletInfo(ctx, senderWalletURL)
	if err != nil {
		return nil, fmt.Errorf("getting sender wallet info: %w", err)
	}

	var payload rs.CreateOutgoingPaymentRequest
	payload.FromCreateOutgoingPaymentWithQuote(rs.CreateOutgoingPaymentWithQuote{
		WalletAddressSchema: *walletAddress.Id,
		QuoteId:             quoteID,
	})

	s.log.Debug("creating outgoing payment",
		"resource_server", *walletAddress.ResourceServer,
		"quote_id", quoteID,
		"wallet", *walletAddress.Id,
	)

	outgoing, err := s.client.OutgoingPayment.Create(ctx, op.OutgoingPaymentCreateParams{
		BaseURL:     *walletAddress.ResourceServer,
		AccessToken: accessToken,
		Payload:     payload,
	})
	if err != nil {
		return nil, fmt.Errorf("creating outgoing payment: %w", err)
	}

	return &outgoing, nil
}

type ShareInput struct {
	Wallet string
	Amount string
}

type splitQuote struct {
	ID          string
	DebitAmount string
}

func (s *PaymentService) InitiateSplit(ctx context.Context, senderWalletURL string, shares []ShareInput) (*OutgoingGrantResult, error) {
	type incomingResult struct {
		ID string
	}

	var incomings []incomingResult
	for _, share := range shares {
		incoming, err := s.CreateIncomingPayment(ctx, share.Wallet, share.Amount)
		if err != nil {
			return nil, fmt.Errorf("incoming payment for %s: %w", share.Wallet, err)
		}
		incomings = append(incomings, incomingResult{ID: *incoming.Id})
	}

	var quotes []splitQuote
	var totalDebit int64
	for _, inc := range incomings {
		quote, err := s.CreateQuote(ctx, senderWalletURL, inc.ID)
		if err != nil {
			return nil, fmt.Errorf("quote for %s: %w", inc.ID, err)
		}
		quotes = append(quotes, splitQuote{
			ID:          *quote.Id,
			DebitAmount: quote.DebitAmount.Value,
		})
		s.log.Info("quote created", "id", *quote.Id, "debit", quote.DebitAmount.Value)
	}

	for _, q := range quotes {
		var v int64
		fmt.Sscanf(q.DebitAmount, "%d", &v)
		totalDebit += v
	}

	walletAddress, err := s.GetWalletInfo(ctx, senderWalletURL)
	if err != nil {
		return nil, fmt.Errorf("getting sender wallet info: %w", err)
	}

	sessionID := uuid.New().String()
	nonce := uuid.New().String()
	totalStr := fmt.Sprintf("%d", totalDebit)

	outgoingAccess := as.AccessOutgoing{
		Type: as.OutgoingPayment,
		Actions: []as.AccessOutgoingActions{
			as.AccessOutgoingActionsCreate,
			as.AccessOutgoingActionsRead,
		},
		Identifier: *walletAddress.Id,
	}

	limits := as.LimitsOutgoing{}
	if err := limits.FromLimitsOutgoing1(as.LimitsOutgoing1{
		DebitAmount: as.Amount{
			Value:      totalStr,
			AssetCode:  walletAddress.AssetCode,
			AssetScale: walletAddress.AssetScale,
		},
	}); err != nil {
		return nil, fmt.Errorf("creating limits: %w", err)
	}
	outgoingAccess.Limits = &limits

	accessItem := as.AccessItem{}
	if err := accessItem.FromAccessOutgoing(outgoingAccess); err != nil {
		return nil, fmt.Errorf("creating access item: %w", err)
	}

	accessToken := struct {
		Access as.Access `json:"access"`
	}{
		Access: []as.AccessItem{accessItem},
	}

	callbackURL := fmt.Sprintf("http://localhost:4001/split/callback?session=%s", sessionID)

	interact := &as.InteractRequest{
		Start: []as.InteractRequestStart{as.InteractRequestStartRedirect},
		Finish: &struct {
			Method as.InteractRequestFinishMethod `json:"method"`
			Nonce  string                         `json:"nonce"`
			Uri    string                         `json:"uri"`
		}{
			Method: as.InteractRequestFinishMethodRedirect,
			Uri:    callbackURL,
			Nonce:  nonce,
		},
	}

	grant, err := s.client.Grant.Request(ctx, op.GrantRequestParams{
		URL: *walletAddress.AuthServer,
		RequestBody: as.GrantRequestWithAccessToken{
			AccessToken: accessToken,
			Interact:    interact,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("requesting outgoing payment grant: %w", err)
	}

	if !grant.IsInteractive() {
		return nil, fmt.Errorf("expected interactive grant for outgoing payment")
	}

	s.sessionsMu.Lock()
	s.sessions[sessionID] = &sessionData{
		ClientNonce:   nonce,
		ServerNonce:   grant.Interact.Finish,
		AuthServerURL: *walletAddress.AuthServer,
		ContinueURI:   grant.Continue.Uri,
		ContinueToken: grant.Continue.AccessToken.Value,
		SenderWallet:  senderWalletURL,
		Quotes:        quotes,
	}
	s.sessionsMu.Unlock()

	return &OutgoingGrantResult{
		SessionID:   sessionID,
		RedirectURL: grant.Interact.Redirect,
	}, nil
}

func (s *PaymentService) HandleSplitCallback(ctx context.Context, sessionID, interactRef, hash string) ([]*rs.OutgoingPayment, error) {
	s.sessionsMu.RLock()
	sd, ok := s.sessions[sessionID]
	s.sessionsMu.RUnlock()
	if !ok {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	base := fmt.Sprintf("%s\n%s\n%s\n%s",
		sd.ClientNonce,
		sd.ServerNonce,
		interactRef,
		sd.AuthServerURL,
	)
	computed := sha256.Sum256([]byte(base))

	received, err := base64.RawStdEncoding.DecodeString(hash)
	if err != nil {
		received, err = base64.StdEncoding.DecodeString(hash)
		if err != nil {
			received, err = base64.RawURLEncoding.DecodeString(hash)
			if err != nil {
				received, err = base64.URLEncoding.DecodeString(hash)
				if err != nil {
					return nil, fmt.Errorf("decoding hash: %w", err)
				}
			}
		}
	}

	if string(computed[:]) != string(received) {
		return nil, fmt.Errorf("hash mismatch")
	}

	grant, err := s.client.Grant.Continue(ctx, op.GrantContinueParams{
		URL:         sd.ContinueURI,
		AccessToken: sd.ContinueToken,
		InteractRef: interactRef,
	})
	if err != nil {
		return nil, fmt.Errorf("continuing grant: %w", err)
	}

	var results []*rs.OutgoingPayment
	for _, q := range sd.Quotes {
		outgoing, err := s.CreateOutgoingPayment(ctx, sd.SenderWallet, q.ID, grant.AccessToken.Value)
		if err != nil {
			return results, fmt.Errorf("outgoing payment for quote %s: %w", q.ID, err)
		}
		results = append(results, outgoing)
		s.log.Info("split outgoing payment created", "id", *outgoing.Id)
	}

	return results, nil
}
