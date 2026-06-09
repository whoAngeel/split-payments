# Splitter

A generic split-payment engine backed by Open Payments. Receives split instructions from an upstream context (e.g., Gallery), orchestrates the full OP payment flow, and returns status. Never holds funds.

## Language

### Entities

**Sender**:
The wallet address that funds a split payment. This is the buyer in the Gallery context, but the Splitter uses the neutral term.
_Avoid_: Payer, buyer, customer

**Recipient**:
A wallet address that receives a share of a split payment.
_Avoid_: Payee, receiver, beneficiary

### Payments

**Split Instruction**:
The request body of `POST /split`. Contains a list of recipients with amounts, the sender's wallet address, and optional metadata.
_Avoid_: Split request, payment order

**Share**:
A single entry within a Split Instruction: a recipient wallet address and an amount.
_Avoid_: Slice, cut, portion

**Session**:
The lifecycle of a single split payment from initiation to completion. Tracks the Open Payments state: incoming payments created, grant requested, user consented, quotes obtained, outgoing payments sent.
_Avoid_: Transaction, payment run, operation
