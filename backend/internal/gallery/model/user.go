package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Email            string `gorm:"uniqueIndex;not null"`
	PasswordHash     string `gorm:"not null"`
	Name             string
	WalletAddressURL string
	KeyID            string
	Galleries        []Gallery `gorm:"foreignKey:UserID"`
}
