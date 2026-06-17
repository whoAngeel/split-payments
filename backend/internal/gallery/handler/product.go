package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type ProductHandler struct {
	svc *service.ProductService
}

func NewProductHandler(svc *service.ProductService) *ProductHandler {
	return &ProductHandler{svc: svc}
}

func (h *ProductHandler) Explore(c *gin.Context) {
	products, err := h.svc.ListAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userID, authenticated := c.Get("userID")

	if !authenticated {
		type publicProduct struct {
			ID        uint   `json:"id"`
			Name      string `json:"name"`
			BasePrice int64  `json:"base_price"`
			AssetCode string `json:"asset_code"`
			AssetScale int   `json:"asset_scale"`
			ArtisanName string `json:"artisan_name"`
		}
		var result []publicProduct
		for _, p := range products {
			result = append(result, publicProduct{
				ID:          p.ID,
				Name:        p.Name,
				BasePrice:   p.BasePrice,
				AssetCode:   p.AssetCode,
				AssetScale:  p.AssetScale,
				ArtisanName: p.Artisan.Name,
			})
		}
		c.JSON(http.StatusOK, result)
		return
	}

	_ = userID
	c.JSON(http.StatusOK, products)
}

type createProductRequest struct {
	Name       string `json:"name" binding:"required"`
	BasePrice  int64  `json:"base_price" binding:"required,min=1"`
	AssetCode  string `json:"asset_code" binding:"required"`
	AssetScale int    `json:"asset_scale"`
}

func (h *ProductHandler) Create(c *gin.Context) {
	artisanID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var req createProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product, err := h.svc.Create(uint(artisanID), req.Name, req.AssetCode, req.BasePrice, req.AssetScale)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, product)
}

func (h *ProductHandler) ListByArtisan(c *gin.Context) {
	artisanID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid artisan_id"})
		return
	}

	products, err := h.svc.GetByArtisan(uint(artisanID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, products)
}

func (h *ProductHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.svc.Delete(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}
