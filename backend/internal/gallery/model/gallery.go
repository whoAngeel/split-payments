package model

type Gallery struct {
	BaseModel
	Name       string      `json:"name" gorm:"not null"`
	UserID     uint        `json:"user_id"`
	User       User        `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Commission *Commission `json:"commission,omitempty" gorm:"foreignKey:GalleryID"`
	Artisans   []Artisan   `json:"artisans,omitempty" gorm:"many2many:gallery_artisans;"`
}
