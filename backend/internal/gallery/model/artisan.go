package model

type Artisan struct {
	BaseModel
	Name             string    `json:"name" gorm:"not null"`
	WalletAddressURL string    `json:"wallet_address_url"`
	ImageURL         string    `json:"image_url"`
	Bio              string    `json:"bio"`
	IsActive         bool      `json:"is_active" gorm:"not null;default:true"`
	Products         []Product `json:"products,omitempty" gorm:"foreignKey:ArtisanID"`
	Galleries        []Gallery `json:"-" gorm:"many2many:gallery_artisans;"`
}
