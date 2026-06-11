package model

import "gorm.io/gorm"

type Product struct {
	gorm.Model
	ArtisanID uint
	Artisan   Artisan `gorm:"foreignKey:ArtisanID"`
	Name      string  `gorm:"not null"`
	BasePrice int64   `gorm:"not null"`
	AssetCode string  `gorm:"not null"`
	AssetScale int    `gorm:"not null;default:2"`
}
