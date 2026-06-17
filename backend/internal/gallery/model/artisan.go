package model

type Artisan struct {
	BaseModel
	Name             string    `json:"name" gorm:"not null"`
	WalletAddressURL string    `json:"wallet_address_url"`
	Products         []Product `json:"products,omitempty" gorm:"foreignKey:ArtisanID"`
	Galleries        []Gallery `json:"-" gorm:"many2many:gallery_artisans;"`
}
