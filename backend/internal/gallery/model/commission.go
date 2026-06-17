package model

type Commission struct {
	BaseModel
	GalleryID uint    `json:"gallery_id" gorm:"uniqueIndex;not null"`
	Gallery   Gallery `json:"-" gorm:"foreignKey:GalleryID"`
	Rate      int     `json:"rate" gorm:"not null"`
}
