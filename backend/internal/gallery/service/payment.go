package service

import (
	"errors"
	"fmt"
	"time"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type PaymentService struct {
	db *gorm.DB
}

func NewPaymentService(db *gorm.DB) *PaymentService {
	return &PaymentService{db: db}
}

type SavePaymentInput struct {
	SessionID string
	BuyerID   uint
	ProductID uint
}

func (s *PaymentService) Save(input SavePaymentInput) (*model.Payment, error) {
	var product model.Product
	if err := s.db.Preload("Artisan.Galleries.Commission").First(&product, input.ProductID).Error; err != nil {
		return nil, fmt.Errorf("product not found: %w", err)
	}

	var galleryID uint
	var artisanShare, galleryShare int64

	if len(product.Artisan.Galleries) > 0 {
		gallery := product.Artisan.Galleries[0]
		galleryID = gallery.ID
		if gallery.Commission != nil {
			galleryShare = product.BasePrice * int64(gallery.Commission.Rate) / 10000
			artisanShare = product.BasePrice - galleryShare
		}
	}

	payment := model.Payment{
		SessionID:    input.SessionID,
		BuyerID:      input.BuyerID,
		ProductID:    input.ProductID,
		ArtisanID:    product.ArtisanID,
		GalleryID:    galleryID,
		TotalAmount:  product.BasePrice,
		AssetCode:    product.AssetCode,
		AssetScale:   product.AssetScale,
		ArtisanShare: artisanShare,
		GalleryShare: galleryShare,
		Status:       "pending",
	}
	if err := s.db.Create(&payment).Error; err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			var existing model.Payment
			if err := s.db.Where("session_id = ?", input.SessionID).First(&existing).Error; err != nil {
				return nil, fmt.Errorf("finding existing payment: %w", err)
			}
			return &existing, nil
		}
		return nil, fmt.Errorf("saving payment: %w", err)
	}
	return &payment, nil
}

func (s *PaymentService) Complete(sessionID, status string) (*model.Payment, error) {
	now := time.Now()
	updates := map[string]interface{}{
		"status": status,
	}
	if status == "completed" {
		updates["completed_at"] = now
	}

	if err := s.db.Model(&model.Payment{}).
		Where("session_id = ?", sessionID).
		Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("completing payment: %w", err)
	}
	var payment model.Payment
	if err := s.db.Where("session_id = ?", sessionID).First(&payment).Error; err != nil {
		return nil, fmt.Errorf("finding payment: %w", err)
	}
	return &payment, nil
}

type PaymentResponse struct {
	ID           uint       `json:"id"`
	SessionID    string     `json:"session_id"`
	ProductName  string     `json:"product_name"`
	ArtisanName  string     `json:"artisan_name"`
	GalleryName  string     `json:"gallery_name"`
	TotalAmount  int64      `json:"total_amount"`
	AssetCode    string     `json:"asset_code"`
	AssetScale   int        `json:"asset_scale"`
	ArtisanShare int64      `json:"artisan_share"`
	GalleryShare int64      `json:"gallery_share"`
	Status       string     `json:"status"`
	CompletedAt  *time.Time `json:"completed_at"`
	CreatedAt    time.Time  `json:"created_at"`
}

// GalleryPaymentsSummary aggregates the numbers a gallery operator needs at
// a glance: gross sales, the gallery's cut, and how many payments are still
// in flight. Amounts are in minor units of AssetCode.
type GalleryPaymentsSummary struct {
	TotalSold      int64  `json:"total_sold"`
	GalleryEarned  int64  `json:"gallery_earned"`
	CompletedCount int    `json:"completed_count"`
	PendingCount   int    `json:"pending_count"`
	AssetCode      string `json:"asset_code"`
	AssetScale     int    `json:"asset_scale"`
}

func (s *PaymentService) ListByGallery(galleryID uint) ([]PaymentResponse, *GalleryPaymentsSummary, error) {
	var payments []model.Payment
	if err := s.db.Preload("Product").
		Preload("Artisan").
		Preload("Gallery").
		Where("gallery_id = ?", galleryID).
		Order("created_at DESC").
		Find(&payments).Error; err != nil {
		return nil, nil, fmt.Errorf("listing gallery payments: %w", err)
	}

	summary := &GalleryPaymentsSummary{AssetCode: "USD", AssetScale: 2}
	result := make([]PaymentResponse, len(payments))
	for i, p := range payments {
		result[i] = PaymentResponse{
			ID:           p.ID,
			SessionID:    p.SessionID,
			ProductName:  p.Product.Name,
			ArtisanName:  p.Artisan.Name,
			GalleryName:  p.Gallery.Name,
			TotalAmount:  p.TotalAmount,
			AssetCode:    p.AssetCode,
			AssetScale:   p.AssetScale,
			ArtisanShare: p.ArtisanShare,
			GalleryShare: p.GalleryShare,
			Status:       p.Status,
			CompletedAt:  p.CompletedAt,
			CreatedAt:    p.CreatedAt,
		}
		if i == 0 {
			summary.AssetCode = p.AssetCode
			summary.AssetScale = p.AssetScale
		}
		switch p.Status {
		case "completed":
			summary.CompletedCount++
			summary.TotalSold += p.TotalAmount
			summary.GalleryEarned += p.GalleryShare
		case "pending":
			summary.PendingCount++
		}
	}
	return result, summary, nil
}

func (s *PaymentService) ListByUser(userID uint) ([]PaymentResponse, error) {
	var payments []model.Payment
	if err := s.db.Preload("Product").
		Preload("Artisan").
		Preload("Gallery").
		Where("buyer_id = ?", userID).
		Order("created_at DESC").
		Find(&payments).Error; err != nil {
		return nil, fmt.Errorf("listing payments: %w", err)
	}
	result := make([]PaymentResponse, len(payments))
	for i, p := range payments {
		result[i] = PaymentResponse{
			ID:           p.ID,
			SessionID:    p.SessionID,
			ProductName:  p.Product.Name,
			ArtisanName:  p.Artisan.Name,
			GalleryName:  p.Gallery.Name,
			TotalAmount:  p.TotalAmount,
			AssetCode:    p.AssetCode,
			AssetScale:   p.AssetScale,
			ArtisanShare: p.ArtisanShare,
			GalleryShare: p.GalleryShare,
			Status:       p.Status,
			CompletedAt:  p.CompletedAt,
			CreatedAt:    p.CreatedAt,
		}
	}
	return result, nil
}
