package model

import "time"

type Payment struct {
	BaseModel
	SessionID    string     `json:"session_id" gorm:"uniqueIndex;not null"`
	BuyerID      uint       `json:"buyer_id" gorm:"not null"`
	Buyer        User       `json:"buyer,omitempty" gorm:"foreignKey:BuyerID"`
	ProductID    uint       `json:"product_id" gorm:"not null"`
	Product      Product    `json:"product,omitempty" gorm:"foreignKey:ProductID"`
	ArtisanID    uint       `json:"artisan_id"`
	Artisan      Artisan    `json:"artisan,omitempty" gorm:"foreignKey:ArtisanID"`
	GalleryID    uint       `json:"gallery_id"`
	Gallery      Gallery    `json:"gallery,omitempty" gorm:"foreignKey:GalleryID"`
	TotalAmount  int64      `json:"total_amount" gorm:"not null"`
	AssetCode    string     `json:"asset_code" gorm:"not null"`
	AssetScale   int        `json:"asset_scale" gorm:"default:2"`
	ArtisanShare int64      `json:"artisan_share"`
	GalleryShare int64      `json:"gallery_share"`
	Status       string     `json:"status" gorm:"default:pending"`
	CompletedAt  *time.Time `json:"completed_at"`
}
