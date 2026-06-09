package service

import (
	"context"
	"fmt"

	"github.com/charmbracelet/log"

	op "github.com/interledger/open-payments-go"
	was "github.com/interledger/open-payments-go/generated/walletaddressserver"
)

type PaymentService struct {
	client *op.AuthenticatedClient
	log    *log.Logger
}

func NewPaymentService(client *op.AuthenticatedClient, logger *log.Logger) *PaymentService {
	return &PaymentService{client: client, log: logger}
}

type WalletAddress struct {
	Wallet string
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
