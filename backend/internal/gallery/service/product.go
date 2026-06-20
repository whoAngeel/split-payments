package service

import (
	"fmt"
	"strings"

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

func (s *ProductService) ListByGallery(galleryID uint) ([]model.Product, error) {
	var products []model.Product
	if err := s.db.
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = products.artisan_id").
		Where("gallery_artisans.gallery_id = ?", galleryID).
		Preload("Artisan").
		Order("products.created_at DESC").
		Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing gallery products: %w", err)
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

func (s *ProductService) Update(productID uint, name, imageURL string, basePrice int64) (*model.Product, error) {
	var product model.Product
	if err := s.db.First(&product, productID).Error; err != nil {
		return nil, fmt.Errorf("product not found")
	}

	if name != "" {
		product.Name = name
	}
	if imageURL != "" {
		product.ImageURL = imageURL
	}
	if basePrice > 0 {
		product.BasePrice = basePrice
	}

	if err := s.db.Save(&product).Error; err != nil {
		return nil, fmt.Errorf("updating product: %w", err)
	}
	return &product, nil
}

func (s *ProductService) ToggleActive(productID uint) (*model.Product, error) {
	var product model.Product
	if err := s.db.First(&product, productID).Error; err != nil {
		return nil, fmt.Errorf("product not found")
	}

	product.IsActive = !product.IsActive
	if err := s.db.Save(&product).Error; err != nil {
		return nil, fmt.Errorf("toggling product: %w", err)
	}
	return &product, nil
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
	if err := s.db.
		Preload("Artisan.Galleries.Commission").
		Joins("JOIN artisans ON artisans.id = products.artisan_id").
		Where("products.is_active = ? AND artisans.is_active = ?", true, true).
		Order("products.created_at DESC").
		Find(&products).Error; err != nil {
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

type ProductDetailResponse struct {
	ID          uint            `json:"id"`
	Name        string          `json:"name"`
	BasePrice   int64           `json:"base_price"`
	AssetCode   string          `json:"asset_code"`
	AssetScale  int             `json:"asset_scale"`
	ImageURL    string          `json:"image_url"`
	Description string          `json:"description"`
	Materials   string          `json:"materials"`
	Dimensions  string          `json:"dimensions"`
	Tags        []string        `json:"tags"`
	Images      []string        `json:"images"`
	Artisan     ArtisanResponse `json:"artisan"`
	Split       *ProductSplit   `json:"split"`
}
type ArtisanResponse struct {
	ID               uint   `json:"id"`
	Name             string `json:"name"`
	ImageURL         string `json:"image_url"`
	Bio              string `json:"bio"`
	WalletAddressURL string `json:"wallet_address_url"`
}

func (s *ProductService) GetDetail(productID uint) (*ProductDetailResponse, error) {
	var product model.Product
	if err := s.db.Preload("Artisan.Galleries.Commission").First(&product, productID).Error; err != nil {
		return nil, fmt.Errorf("product not found: %w", err)
	}
	if !product.IsActive || !product.Artisan.IsActive {
		return nil, fmt.Errorf("product not found")
	}
	var detail model.ProductDetail
	if err := s.db.Where("product_id = ?", productID).First(&detail).Error; err != nil {
		if !IsNotFound(err) {
			return nil, fmt.Errorf("loading product detail: %w", err)
		}
	}
	var images []model.ProductImage
	s.db.Where("product_id = ?", productID).Order("sort_order ASC").Find(&images)
	imageURLs := make([]string, len(images))
	for i, img := range images {
		imageURLs[i] = img.ImageURL
	}
	tags := splitTags(detail.Tags)
	resp := ProductDetailResponse{
		ID:          product.ID,
		Name:        product.Name,
		BasePrice:   product.BasePrice,
		AssetCode:   product.AssetCode,
		AssetScale:  product.AssetScale,
		ImageURL:    product.ImageURL,
		Description: detail.Description,
		Materials:   detail.Materials,
		Dimensions:  detail.Dimensions,
		Tags:        tags,
		Images:      imageURLs,
		Artisan: ArtisanResponse{
			ID:               product.Artisan.ID,
			Name:             product.Artisan.Name,
			ImageURL:         product.Artisan.ImageURL,
			Bio:              product.Artisan.Bio,
			WalletAddressURL: product.Artisan.WalletAddressURL,
		},
	}
	if len(product.Artisan.Galleries) > 0 && product.Artisan.Galleries[0].Commission != nil {
		rate := product.Artisan.Galleries[0].Commission.Rate
		galleryPct := rate / 100
		resp.Split = &ProductSplit{
			ArtisanPercent:  100 - galleryPct,
			GalleryPercent:  galleryPct,
			PlatformPercent: 0,
		}
	}
	return &resp, nil
}

func splitTags(tags string) []string {
	if tags == "" {
		return nil
	}
	cleaned := strings.Trim(tags, "{}")
	parts := strings.Split(cleaned, ",")
	result := make([]string, len(parts))
	for i, p := range parts {
		result[i] = strings.TrimSpace(p)
	}
	return result
}
func IsNotFound(err error) bool {
	return err != nil && err.Error() == "record not found"
}
