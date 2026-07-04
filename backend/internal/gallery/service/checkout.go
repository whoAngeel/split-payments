package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	shared "github.com/whoAngeel/openpayments/internal/shared/model"
	"gorm.io/gorm"
)

type CheckoutService struct {
	db             *gorm.DB
	splitterURL    string
	splitterAPIKey string
	client         *http.Client
}

func NewCheckoutService(db *gorm.DB, splitterURL, splitterAPIKey string) *CheckoutService {
	return &CheckoutService{
		db:             db,
		splitterURL:    splitterURL,
		splitterAPIKey: splitterAPIKey,
		client:         &http.Client{Timeout: 30 * time.Second},
	}
}

func (s *CheckoutService) Checkout(buyerWallet string, productID uint) (*shared.SplitResponse, error) {
	var product model.Product
	if err := s.db.Preload("Artisan.Galleries.Commission").Preload("Artisan.Galleries.User").First(&product, productID).Error; err != nil {
		return nil, fmt.Errorf("product not found")
	}

	if len(product.Artisan.Galleries) == 0 {
		return nil, fmt.Errorf("artisan not linked to any gallery")
	}

	gallery := product.Artisan.Galleries[0]

	commissionRate := product.CommissionRate
	if commissionRate == 0 && gallery.Commission != nil {
		commissionRate = gallery.Commission.Rate
	}
	if commissionRate == 0 {
		return nil, fmt.Errorf("no commission set for this product")
	}
	galleryShare := product.BasePrice * int64(commissionRate) / 10000
	artisanShare := product.BasePrice - galleryShare

	galleryWallet := gallery.User.WalletAddressURL
	if galleryWallet == "" {
		galleryWallet = product.Artisan.WalletAddressURL
	}

	splitReq := shared.SplitRequest{
		SenderWallet: buyerWallet,
		Shares: []shared.Share{
			{
				Wallet: product.Artisan.WalletAddressURL,
				Amount: fmt.Sprintf("%d", artisanShare),
			},
			{
				Wallet: galleryWallet,
				Amount: fmt.Sprintf("%d", galleryShare),
			},
		},
	}

	body, _ := json.Marshal(splitReq)
	req, err := http.NewRequest("POST", s.splitterURL+"/split", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("creating request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.splitterAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("calling splitter: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("splitter error %d: %s", resp.StatusCode, string(respBody))
	}

	var splitResp shared.SplitResponse
	if err := json.NewDecoder(resp.Body).Decode(&splitResp); err != nil {
		return nil, fmt.Errorf("decoding response: %w", err)
	}

	return &splitResp, nil
}
