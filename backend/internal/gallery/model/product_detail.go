package model

type ProductDetail struct {
	BaseModel
	ProductID   uint   `json:"product_id" gorm:"uniqueIndex;not null"`
	Description string `json:"description"`
	Materials   string `json:"materials"`
	Dimensions  string `json:"dimensions"`
	Tags        string `json:"tags"`
}

type ProductImage struct {
	BaseModel
	ProductID uint   `json:"product_id" gorm:"not null"`
	ImageURL  string `json:"image_url" gorm:"not null"`
	SortOrder int    `json:"sort_order" gorm:"default:0"`
}
