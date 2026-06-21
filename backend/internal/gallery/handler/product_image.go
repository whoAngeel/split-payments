package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/gorm"
)

type ProductImageHandler struct {
	db *gorm.DB
}

func NewProductImageHandler(db *gorm.DB) *ProductImageHandler {
	return &ProductImageHandler{db: db}
}

func (h *ProductImageHandler) List(c *gin.Context) {
	productID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid product id"})
		return
	}

	var images []model.ProductImage
	if err := h.db.Where("product_id = ?", uint(productID)).Order("sort_order ASC").Find(&images).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "listing images"})
		return
	}

	c.JSON(http.StatusOK, images)
}

type addImageRequest struct {
	ImageURL string `json:"image_url" binding:"required"`
}

func (h *ProductImageHandler) Add(c *gin.Context) {
	productID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid product id"})
		return
	}

	var req addImageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var count int64
	h.db.Model(&model.ProductImage{}).Where("product_id = ?", uint(productID)).Count(&count)
	if count >= 5 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "max 5 images per product"})
		return
	}

	img := model.ProductImage{
		ProductID: uint(productID),
		ImageURL:  req.ImageURL,
		SortOrder: int(count),
	}
	if err := h.db.Create(&img).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "adding image"})
		return
	}

	c.JSON(http.StatusCreated, img)
}

func (h *ProductImageHandler) Delete(c *gin.Context) {
	productID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid product id"})
		return
	}
	imageID, err := strconv.ParseUint(c.Param("image_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid image id"})
		return
	}

	result := h.db.Where("id = ? AND product_id = ?", uint(imageID), uint(productID)).Delete(&model.ProductImage{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "image not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}
