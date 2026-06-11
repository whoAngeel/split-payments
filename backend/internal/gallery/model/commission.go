package model

import "gorm.io/gorm"

type Commission struct {
	gorm.Model
	GalleryID uint    `gorm:"uniqueIndex;not null"`
	Gallery   Gallery `gorm:"foreignKey:GalleryID"`
	Rate      int     `gorm:"not null"`
}
