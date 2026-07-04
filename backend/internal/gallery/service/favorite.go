package service

import (
	"fmt"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type FavoriteService struct {
	db *gorm.DB
}

func NewFavoriteService(db *gorm.DB) *FavoriteService {
	return &FavoriteService{db: db}
}

func (s *FavoriteService) Toggle(userID, productID uint) (bool, error) {
	var fav model.Favorite
	result := s.db.Where("user_id = ? AND product_id = ?", userID, productID).First(&fav)
	if result.Error == nil {
		if err := s.db.Delete(&fav).Error; err != nil {
			return false, fmt.Errorf("removing favorite: %w", err)
		}
		return false, nil
	}

	if result.Error == gorm.ErrRecordNotFound {
		fav = model.Favorite{UserID: userID, ProductID: productID}
		if err := s.db.Create(&fav).Error; err != nil {
			return false, fmt.Errorf("adding favorite: %w", err)
		}
		return true, nil
	}

	return false, fmt.Errorf("checking favorite: %w", result.Error)
}

func (s *FavoriteService) GetFavoritedProductIDs(userID uint) (map[uint]bool, error) {
	var favs []model.Favorite
	if err := s.db.Select("product_id").Where("user_id = ?", userID).Find(&favs).Error; err != nil {
		return nil, fmt.Errorf("listing favorites: %w", err)
	}
	result := make(map[uint]bool, len(favs))
	for _, f := range favs {
		result[f.ProductID] = true
	}
	return result, nil
}

func (s *FavoriteService) ListByUser(userID uint) ([]model.Favorite, error) {
	var favorites []model.Favorite
	if err := s.db.Where("user_id = ?", userID).Preload("Product.Artisan").Find(&favorites).Error; err != nil {
		return nil, fmt.Errorf("listing favorites: %w", err)
	}
	return favorites, nil
}
