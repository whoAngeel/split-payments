package service

import (
	"fmt"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type ProductService struct {
	db *gorm.DB
}

func NewProductService(db *gorm.DB) *ProductService {
	return &ProductService{db: db}
}

func (s *ProductService) Create(artisanID uint, name, assetCode string, basePrice int64, assetScale int, imageURL string) (*model.Product, error) {
	product := model.Product{
		ArtisanID:  artisanID,
		Name:       name,
		BasePrice:  basePrice,
		AssetCode:  assetCode,
		AssetScale: assetScale,
		ImageURL:   imageURL,
	}
	if err := s.db.Create(&product).Error; err != nil {
		return nil, fmt.Errorf("creating product: %w", err)
	}
	return &product, nil
}

func (s *ProductService) GetByArtisan(artisanID uint) ([]model.Product, error) {
	var products []model.Product
	if err := s.db.Where("artisan_id = ?", artisanID).Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing products: %w", err)
	}
	return products, nil
}

func (s *ProductService) ListAll() ([]model.Product, error) {
	var products []model.Product
	if err := s.db.Preload("Artisan").Order("created_at DESC").Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing products: %w", err)
	}
	return products, nil
}

func (s *ProductService) Delete(productID uint) error {
	if err := s.db.Delete(&model.Product{}, productID).Error; err != nil {
		return fmt.Errorf("deleting product: %w", err)
	}
	return nil
}

type ProductSplit struct {
	ArtisanPercent  int `json:"artisan_percent"`
	GalleryPercent  int `json:"gallery_percent"`
	PlatformPercent int `json:"platform_percent"`
}

type ExploreProduct struct {
	ID          uint          `json:"id"`
	Name        string        `json:"name"`
	BasePrice   int64         `json:"base_price"`
	AssetCode   string        `json:"asset_code"`
	AssetScale  int           `json:"asset_scale"`
	ArtisanName string        `json:"artisan_name"`
	ImageURL    string        `json:"image_url"`
	Split       *ProductSplit `json:"split"`
}

func (s *ProductService) ListAllExplore() ([]ExploreProduct, error) {
	var products []model.Product
	if err := s.db.Preload("Artisan.Galleries.Commission").Order("created_at DESC").Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing products: %w", err)
	}

	result := make([]ExploreProduct, len(products))
	for i, p := range products {
		ep := ExploreProduct{
			ID:          p.ID,
			Name:        p.Name,
			BasePrice:   p.BasePrice,
			AssetCode:   p.AssetCode,
			AssetScale:  p.AssetScale,
			ArtisanName: p.Artisan.Name,
			ImageURL:    p.ImageURL,
		}
		if len(p.Artisan.Galleries) > 0 && p.Artisan.Galleries[0].Commission != nil {
			rate := p.Artisan.Galleries[0].Commission.Rate
			galleryPct := rate / 100
			ep.Split = &ProductSplit{
				ArtisanPercent:  100 - galleryPct,
				GalleryPercent:  galleryPct,
				PlatformPercent: 0,
			}
		}
		result[i] = ep
	}
	return result, nil
}
