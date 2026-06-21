package service

import (
	"fmt"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type GalleryService struct {
	db *gorm.DB
}

func NewGalleryService(db *gorm.DB) *GalleryService {
	return &GalleryService{db: db}
}

func (s *GalleryService) CreateGallery(userID uint, name string) (*model.Gallery, error) {
	var user model.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("user not found")
	}
	if user.Role != "gallery_admin" {
		return nil, fmt.Errorf("only gallery admins can create galleries")
	}

	var count int64
	if err := s.db.Model(&model.Gallery{}).Where("user_id = ?", userID).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("checking existing galleries: %w", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("user already has a gallery")
	}

	gallery := model.Gallery{UserID: userID, Name: name}
	if err := s.db.Create(&gallery).Error; err != nil {
		return nil, fmt.Errorf("creating gallery: %w", err)
	}
	return &gallery, nil
}

func (s *GalleryService) GetGallery(galleryID, userID uint) (*model.Gallery, error) {
	var gallery model.Gallery
	if err := s.db.Preload("Commission").Preload("Artisans").Where("id = ? AND user_id = ?", galleryID, userID).First(&gallery).Error; err != nil {
		return nil, fmt.Errorf("gallery not found")
	}
	return &gallery, nil
}

func (s *GalleryService) ListGalleries(userID uint) ([]model.Gallery, error) {
	var galleries []model.Gallery
	if err := s.db.Where("user_id = ?", userID).Find(&galleries).Error; err != nil {
		return nil, fmt.Errorf("listing galleries: %w", err)
	}
	return galleries, nil
}

func (s *GalleryService) SetCommission(galleryID, userID uint, rate int) (*model.Commission, error) {
	var gallery model.Gallery
	if err := s.db.Where("id = ? AND user_id = ?", galleryID, userID).First(&gallery).Error; err != nil {
		return nil, fmt.Errorf("gallery not found")
	}

	commission := model.Commission{
		GalleryID: galleryID,
		Rate:      rate,
	}

	if err := s.db.Where("gallery_id = ?", galleryID).
		Assign(model.Commission{Rate: rate}).
		FirstOrCreate(&commission).Error; err != nil {
		return nil, fmt.Errorf("setting commission: %w", err)
	}

	return &commission, nil
}

func (s *GalleryService) AddArtisan(galleryID, userID, artisanID uint) error {
	var gallery model.Gallery
	if err := s.db.Where("id = ? AND user_id = ?", galleryID, userID).First(&gallery).Error; err != nil {
		return fmt.Errorf("gallery not found")
	}
	var artisan model.Artisan
	if err := s.db.First(&artisan, artisanID).Error; err != nil {
		return fmt.Errorf("artisan not found")
	}
	return s.db.Model(&gallery).Association("Artisans").Append(&artisan)
}

type GalleryDashboard struct {
	Gallery        model.Gallery `json:"gallery"`
	ActiveArtisans int64         `json:"active_artisans"`
	TotalArtisans  int64         `json:"total_artisans"`
	ActiveProducts int64         `json:"active_products"`
	TotalProducts  int64         `json:"total_products"`
}

func (s *GalleryService) GetDashboard(galleryID, userID uint) (*GalleryDashboard, error) {
	gallery, err := s.GetGallery(galleryID, userID)
	if err != nil {
		return nil, err
	}

	dashboard := &GalleryDashboard{
		Gallery:       *gallery,
		TotalArtisans: int64(len(gallery.Artisans)),
	}

	s.db.Model(&model.Artisan{}).
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = artisans.id").
		Where("gallery_artisans.gallery_id = ? AND artisans.is_active = ?", galleryID, true).
		Count(&dashboard.ActiveArtisans)

	s.db.Model(&model.Product{}).
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = products.artisan_id").
		Where("gallery_artisans.gallery_id = ?", galleryID).
		Count(&dashboard.TotalProducts)

	s.db.Model(&model.Product{}).
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = products.artisan_id").
		Where("gallery_artisans.gallery_id = ? AND products.is_active = ?", galleryID, true).
		Count(&dashboard.ActiveProducts)

	return dashboard, nil
}

func (s *GalleryService) RemoveArtisan(galleryID, userID, artisanID uint) error {
	var gallery model.Gallery
	if err := s.db.Where("id = ? AND user_id = ?", galleryID, userID).First(&gallery).Error; err != nil {
		return fmt.Errorf("gallery not found")
	}
	var artisan model.Artisan
	if err := s.db.First(&artisan, artisanID).Error; err != nil {
		return fmt.Errorf("artisan not found")
	}
	return s.db.Model(&gallery).Association("Artisans").Delete(&artisan)
}
