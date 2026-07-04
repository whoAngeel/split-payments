package model

import "time"

type PasswordReset struct {
	BaseModel
	UserID    uint       `json:"user_id" gorm:"index;not null"`
	CodeHash  string     `json:"-" gorm:"not null"`
	ExpiresAt time.Time  `json:"expires_at" gorm:"not null"`
	Attempts  int        `json:"-" gorm:"not null;default:0"`
	UsedAt    *time.Time `json:"-"`
}
