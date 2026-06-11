package model

import "gorm.io/gorm"

type Artisan struct {
	gorm.Model
	Name             string `gorm:"not null"`
	WalletAddressURL string
	Products         []Product  `gorm:"foreignKey:ArtisanID"`
	Galleries        []Gallery  `gorm:"many2many:gallery_artisans;"`
}
