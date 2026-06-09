package service

import (
	"context"
	"fmt"

	"github.com/charmbracelet/log"

	op "github.com/interledger/open-payments-go"
	was "github.com/interledger/open-payments-go/generated/walletaddressserver"
	as "github.com/interledger/open-payments-go/generated/authserver"
)

type PaymentService struct {
	client *op.AuthenticatedClient
	log    *log.Logger
}

func NewPaymentService(client *op.AuthenticatedClient, logger *log.Logger) *PaymentService {
	return &PaymentService{client: client, log: logger}
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

func (s *PaymentService) CreateIncomingPaymentGrant(ctx context.Context, walletURL string) (*op.Grant, error) {
	walletAddress, err := s.GetWalletInfo(ctx, walletURL)
	if err != nil {
		return nil, fmt.Errorf("getting wallet address info: %w", err)
	}

	incomingAccess := as.AccessIncoming{
		Type: as.IncomingPayment,
		Actions: []as.AccessIncomingActions{
			as.AccessIncomingActionsCreate,
		},
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

	return &grant, nil
}