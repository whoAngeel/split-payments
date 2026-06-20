package model

type Favorite struct {
	BaseModel
	UserID    uint    `json:"user_id" gorm:"uniqueIndex:idx_user_product;not null"`
	ProductID uint    `json:"product_id" gorm:"uniqueIndex:idx_user_product;not null"`
	Product   Product `json:"product,omitempty" gorm:"foreignKey:ProductID"`
}
