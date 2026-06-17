package model

type Product struct {
	BaseModel
	ArtisanID uint    `json:"artisan_id"`
	Artisan   Artisan `json:"artisan,omitempty" gorm:"foreignKey:ArtisanID"`
	Name      string  `json:"name" gorm:"not null"`
	BasePrice int64   `json:"base_price" gorm:"not null"`
	AssetCode string  `json:"asset_code" gorm:"not null"`
	AssetScale int    `json:"asset_scale" gorm:"not null;default:2"`
}
