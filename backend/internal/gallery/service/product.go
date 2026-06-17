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

func (s *ProductService) Create(artisanID uint, name, assetCode string, basePrice int64, assetScale int) (*model.Product, error) {
	product := model.Product{
		ArtisanID:  artisanID,
		Name:       name,
		BasePrice:  basePrice,
		AssetCode:  assetCode,
		AssetScale: assetScale,
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
