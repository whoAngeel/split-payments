package service

import (
	"fmt"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type ArtisanService struct {
	db *gorm.DB
}

func NewArtisanService(db *gorm.DB) *ArtisanService {
	return &ArtisanService{db: db}
}

func (s *ArtisanService) Create(name, walletAddressURL, imageURL, bio, location, specialty, craftType, tags string) (*model.Artisan, error) {
	artisan := model.Artisan{
		Name:             name,
		WalletAddressURL: walletAddressURL,
		ImageURL:         imageURL,
		Bio:              bio,
		Location:         location,
		Specialty:        specialty,
		CraftType:        craftType,
		Tags:             tags,
	}
	if err := s.db.Create(&artisan).Error; err != nil {
		return nil, fmt.Errorf("creating artisan: %w", err)
	}
	return &artisan, nil
}

func (s *ArtisanService) Get(id uint) (*model.Artisan, error) {
	var artisan model.Artisan
	if err := s.db.Preload("Products").First(&artisan, id).Error; err != nil {
		return nil, fmt.Errorf("artisan not found")
	}
	return &artisan, nil
}

func (s *ArtisanService) List() ([]model.Artisan, error) {
	var artisans []model.Artisan
	if err := s.db.Find(&artisans).Error; err != nil {
		return nil, fmt.Errorf("listing artisans: %w", err)
	}
	return artisans, nil
}

func (s *ArtisanService) ListByGallery(galleryID uint) ([]model.Artisan, error) {
	var artisans []model.Artisan
	if err := s.db.
		Joins("JOIN gallery_artisans ON gallery_artisans.artisan_id = artisans.id").
		Where("gallery_artisans.gallery_id = ?", galleryID).
		Find(&artisans).Error; err != nil {
		return nil, fmt.Errorf("listing gallery artisans: %w", err)
	}
	return artisans, nil
}

func (s *ArtisanService) Update(id uint, name, walletAddressURL, imageURL, bio, location, specialty, craftType, tags string) (*model.Artisan, error) {
	var artisan model.Artisan
	if err := s.db.First(&artisan, id).Error; err != nil {
		return nil, fmt.Errorf("artisan not found")
	}

	if name != "" {
		artisan.Name = name
	}
	artisan.WalletAddressURL = walletAddressURL
	artisan.ImageURL = imageURL
	artisan.Bio = bio
	artisan.Location = location
	artisan.Specialty = specialty
	artisan.CraftType = craftType
	artisan.Tags = tags

	if err := s.db.Save(&artisan).Error; err != nil {
		return nil, fmt.Errorf("updating artisan: %w", err)
	}
	return &artisan, nil
}

func (s *ArtisanService) Delete(id uint) error {
	var count int64
	if err := s.db.Model(&model.Product{}).Where("artisan_id = ?", id).Count(&count).Error; err != nil {
		return fmt.Errorf("checking products: %w", err)
	}
	if count > 0 {
		return fmt.Errorf("cannot delete artisan with existing products")
	}
	if err := s.db.Delete(&model.Artisan{}, id).Error; err != nil {
		return fmt.Errorf("deleting artisan: %w", err)
	}
	return nil
}

func (s *ArtisanService) ToggleActive(id uint, cascade bool) (*model.Artisan, error) {
	var artisan model.Artisan
	if err := s.db.First(&artisan, id).Error; err != nil {
		return nil, fmt.Errorf("artisan not found")
	}

	artisan.IsActive = !artisan.IsActive
	if err := s.db.Save(&artisan).Error; err != nil {
		return nil, fmt.Errorf("toggling artisan: %w", err)
	}

	if cascade {
		s.db.Model(&model.Product{}).Where("artisan_id = ?", id).Update("is_active", artisan.IsActive)
	}

	return &artisan, nil
}
