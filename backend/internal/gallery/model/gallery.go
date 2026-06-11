package model

import "gorm.io/gorm"

type Gallery struct {
	gorm.Model
	Name   string `gorm:"not null"`
	UserID uint
	User   User `gorm:"foreignKey:UserID"`
	Commission *Commission `gorm:"foreignKey:GalleryID"`
	Artisans   []Artisan   `gorm:"many2many:gallery_artisans;"`
}
