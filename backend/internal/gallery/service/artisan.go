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

func (s *ArtisanService) Create(name, walletAddressURL string) (*model.Artisan, error) {
	artisan := model.Artisan{
		Name:             name,
		WalletAddressURL: walletAddressURL,
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
