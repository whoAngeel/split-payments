package model

type User struct {
	BaseModel
	Email            string    `json:"email" gorm:"uniqueIndex;not null"`
	PasswordHash     string    `json:"-" gorm:"not null"`
	Name             string    `json:"name"`
	WalletAddressURL string    `json:"wallet_address_url"`
	Role             string    `json:"role" gorm:"not null;default:buyer"`
	KeyID            string    `json:"key_id"`
	Galleries        []Gallery `json:"galleries,omitempty" gorm:"foreignKey:UserID"`
}
