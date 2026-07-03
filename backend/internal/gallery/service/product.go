package service

import (
	"fmt"
	"strings"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	shared "github.com/whoAngeel/openpayments/internal/shared/model"
	"gorm.io/gorm"
)

type ProductService struct {
	db *gorm.DB
}

func NewProductService(db *gorm.DB) *ProductService {
	return &ProductService{db: db}
}

func (s *ProductService) Create(artisanID uint, name, assetCode string, basePrice int64, assetScale int, commissionRate int, imageURL, description, materials, dimensions, tags string) (*model.Product, error) {
	product := model.Product{
		ArtisanID:      artisanID,
		Name:           name,
		BasePrice:      basePrice,
		AssetCode:      assetCode,
		AssetScale:     assetScale,
		ImageURL:       imageURL,
		CommissionRate: commissionRate,
	}
	if assetCode == "" {
		product.AssetCode = "USD"
	}
	if assetScale == 0 {
		product.AssetScale = 2
	}

	if err := s.db.Create(&product).Error; err != nil {
		return nil, fmt.Errorf("creating product: %w", err)
	}

	if description != "" || materials != "" || dimensions != "" || tags != "" {
		detail := model.ProductDetail{
			ProductID:   product.ID,
			Description: description,
			Materials:   materials,
			Dimensions:  dimensions,
			Tags:        tags,
		}
		if err := s.db.Create(&detail).Error; err != nil {
			return nil, fmt.Errorf("creating product detail: %w", err)
		}
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

func (s *ProductService) ListByGalleryPaginated(galleryID uint, page, limit int) (*shared.PageResponse, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	var total int64
	s.db.Table("products").
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = products.artisan_id").
		Where("gallery_artisans.gallery_id = ?", galleryID).
		Count(&total)

	var products []model.Product
	offset := (page - 1) * limit
	if err := s.db.
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = products.artisan_id").
		Where("gallery_artisans.gallery_id = ?", galleryID).
		Preload("Artisan").
		Order("products.id DESC").
		Offset(offset).
		Limit(limit).
		Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing gallery products: %w", err)
	}

	return &shared.PageResponse{
		Items: products,
		Total: total,
		Page:  page,
		Limit: limit,
	}, nil
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

func (s *ProductService) Update(productID uint, name, imageURL string, basePrice int64, commissionRate int, description, materials, dimensions, tags string) (*model.Product, error) {
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
	if commissionRate >= 0 {
		product.CommissionRate = commissionRate
	}

	if err := s.db.Save(&product).Error; err != nil {
		return nil, fmt.Errorf("updating product: %w", err)
	}

	if description != "" || materials != "" || dimensions != "" || tags != "" {
		var detail model.ProductDetail
		result := s.db.Where("product_id = ?", productID).First(&detail)
		detail.ProductID = productID
		detail.Description = description
		detail.Materials = materials
		detail.Dimensions = dimensions
		detail.Tags = tags
		if result.Error != nil {
			if err := s.db.Create(&detail).Error; err != nil {
				return nil, fmt.Errorf("creating product detail: %w", err)
			}
		} else {
			if err := s.db.Save(&detail).Error; err != nil {
				return nil, fmt.Errorf("updating product detail: %w", err)
			}
		}
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
	IsFavorited bool          `json:"is_favorited"`
}

func (s *ProductService) ListAllExploreCursor(cursor uint, limit int) (*shared.CursorResponse, error) {
	if limit < 1 || limit > 50 {
		limit = 20
	}

	var products []model.Product
	query := s.db.
		Preload("Artisan").
		Joins("JOIN artisans ON artisans.id = products.artisan_id").
		Where("products.is_active = ? AND artisans.is_active = ?", true, true).
		Order("products.id DESC").
		Limit(limit + 1)

	if cursor > 0 {
		query = query.Where("products.id < ?", cursor)
	}

	if err := query.Find(&products).Error; err != nil {
		return nil, fmt.Errorf("listing explore products: %w", err)
	}

	var nextCursor uint
	if len(products) > limit {
		nextCursor = products[len(products)-1].ID
		products = products[:len(products)-1]
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
		if p.CommissionRate > 0 {
			galleryPct := p.CommissionRate / 100
			ep.Split = &ProductSplit{
				ArtisanPercent:  100 - galleryPct,
				GalleryPercent:  galleryPct,
				PlatformPercent: 0,
			}
		}
		result[i] = ep
	}

	return &shared.CursorResponse{
		Items:      result,
		NextCursor: nextCursor,
	}, nil
}

type ProductDetailResponse struct {
	ID              uint            `json:"id"`
	Name            string          `json:"name"`
	BasePrice       int64           `json:"base_price"`
	AssetCode       string          `json:"asset_code"`
	AssetScale      int             `json:"asset_scale"`
	ImageURL        string          `json:"image_url"`
	Description     string          `json:"description"`
	Materials       string          `json:"materials"`
	Dimensions      string          `json:"dimensions"`
	Tags            []string        `json:"tags"`
	Images          []string        `json:"images"`
	Artisan         ArtisanResponse `json:"artisan"`
	Split           *ProductSplit   `json:"split"`
	IsActive        bool            `json:"is_active"`
	ArtisanIsActive bool            `json:"artisan_is_active"`
}
type ArtisanResponse struct {
	ID               uint   `json:"id"`
	Name             string `json:"name"`
	ImageURL         string `json:"image_url"`
	Bio              string `json:"bio"`
	WalletAddressURL string `json:"wallet_address_url"`
}

func (s *ProductService) GetDetail(productID uint) (*ProductDetailResponse, error) {
	resp, err := s.getDetail(productID)
	if err != nil {
		return nil, err
	}
	if !resp.IsActive || !resp.ArtisanIsActive {
		return nil, fmt.Errorf("product not found")
	}
	return resp, nil
}

func (s *ProductService) GetDetailAdmin(productID uint) (*ProductDetailResponse, error) {
	return s.getDetail(productID)
}

type productDetailData struct {
	Product         model.Product
	Detail          model.ProductDetail
	Images          []string
	IsActive        bool
	ArtisanIsActive bool
}

func (s *ProductService) getDetail(productID uint) (*ProductDetailResponse, error) {
	var product model.Product
	if err := s.db.Preload("Artisan").First(&product, productID).Error; err != nil {
		return nil, fmt.Errorf("product not found: %w", err)
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
		IsActive:    product.IsActive,
		Artisan: ArtisanResponse{
			ID:               product.Artisan.ID,
			Name:             product.Artisan.Name,
			ImageURL:         product.Artisan.ImageURL,
			Bio:              product.Artisan.Bio,
			WalletAddressURL: product.Artisan.WalletAddressURL,
		},
		ArtisanIsActive: product.Artisan.IsActive,
	}
	if product.CommissionRate > 0 {
		galleryPct := product.CommissionRate / 100
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
