package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type ProductHandler struct {
	svc    *service.ProductService
	favSvc *service.FavoriteService
}

func NewProductHandler(svc *service.ProductService, favSvc *service.FavoriteService) *ProductHandler {
	return &ProductHandler{svc: svc, favSvc: favSvc}
}

type exploreProductResponse struct {
	ID          uint                  `json:"id"`
	Name        string                `json:"name"`
	BasePrice   int64                 `json:"base_price"`
	AssetCode   string                `json:"asset_code"`
	AssetScale  int                   `json:"asset_scale"`
	ArtisanName string                `json:"artisan_name"`
	ImageURL    string                `json:"image_url"`
	Split       *service.ProductSplit `json:"split"`
	IsFavorited bool                  `json:"is_favorited"`
}

func (h *ProductHandler) Explore(c *gin.Context) {
	products, err := h.svc.ListAllExplore()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userID, authenticated := c.Get("userID")

	var favIDs map[uint]bool
	if authenticated {
		favIDs, _ = h.favSvc.GetFavoritedProductIDs(userID.(uint))
	}

	result := make([]exploreProductResponse, 0, len(products))
	for _, p := range products {
		r := exploreProductResponse{
			ID:          p.ID,
			Name:        p.Name,
			BasePrice:   p.BasePrice,
			AssetCode:   p.AssetCode,
			AssetScale:  p.AssetScale,
			ArtisanName: p.ArtisanName,
			ImageURL:    p.ImageURL,
			Split:       p.Split,
			IsFavorited: favIDs[p.ID],
		}
		result = append(result, r)
	}

	c.JSON(http.StatusOK, result)
}

type createProductRequest struct {
	Name           string `json:"name" binding:"required"`
	BasePrice      int64  `json:"base_price" binding:"required,min=1"`
	AssetCode      string `json:"asset_code" binding:"required"`
	AssetScale     int    `json:"asset_scale"`
	ImageURL       string `json:"image_url"`
	CommissionRate int    `json:"commission_rate"`
}

func (h *ProductHandler) Create(c *gin.Context) {
	artisanID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid artisan_id"})
		return
	}

	var req createProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product, err := h.svc.Create(uint(artisanID), req.Name, req.AssetCode, req.BasePrice, req.AssetScale, req.CommissionRate, req.ImageURL)
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

func (h *ProductHandler) ListByGallery(c *gin.Context) {
	galleryID := c.GetUint("galleryID")

	products, err := h.svc.ListByGallery(galleryID)
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

type updateProductRequest struct {
	Name           string `json:"name"`
	BasePrice      int64  `json:"base_price"`
	ImageURL       string `json:"image_url"`
	CommissionRate int    `json:"commission_rate"`
}

func (h *ProductHandler) Update(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var req updateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product, err := h.svc.Update(uint(id), req.Name, req.ImageURL, req.BasePrice, req.CommissionRate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, product)
}

func (h *ProductHandler) GetDetail(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	detail, err := h.svc.GetDetail(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, detail)
}

func (h *ProductHandler) ToggleActive(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	product, err := h.svc.ToggleActive(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, product)
}
