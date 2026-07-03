package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type ArtisanHandler struct {
	svc     *service.ArtisanService
	gallerySvc *service.GalleryService
}

func NewArtisanHandler(svc *service.ArtisanService, gallerySvc *service.GalleryService) *ArtisanHandler {
	return &ArtisanHandler{svc: svc, gallerySvc: gallerySvc}
}

type createArtisanRequest struct {
	Name             string `json:"name" binding:"required"`
	WalletAddressURL string `json:"wallet_address_url" binding:"required"`
	ImageURL         string `json:"image_url"`
	Bio              string `json:"bio"`
	Location         string `json:"location"`
	Specialty        string `json:"specialty"`
	CraftType        string `json:"craft_type"`
	Tags             string `json:"tags"`
}

func (h *ArtisanHandler) Create(c *gin.Context) {
	galleryID := c.GetUint("galleryID")

	var req createArtisanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	artisan, err := h.svc.Create(req.Name, req.WalletAddressURL, req.ImageURL, req.Bio, req.Location, req.Specialty, req.CraftType, req.Tags)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := h.gallerySvc.AddArtisan(galleryID, c.GetUint("userID"), artisan.ID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, artisan)
}

func (h *ArtisanHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	result, err := h.svc.ListByGalleryPaginated(c.GetUint("galleryID"), page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

func (h *ArtisanHandler) Get(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	artisan, err := h.svc.Get(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "artisan not found"})
		return
	}

	c.JSON(http.StatusOK, artisan)
}

type updateArtisanRequest struct {
	Name             string `json:"name"`
	WalletAddressURL string `json:"wallet_address_url"`
	ImageURL         string `json:"image_url"`
	Bio              string `json:"bio"`
	Location         string `json:"location"`
	Specialty        string `json:"specialty"`
	CraftType        string `json:"craft_type"`
	Tags             string `json:"tags"`
}

func (h *ArtisanHandler) Update(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var req updateArtisanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	artisan, err := h.svc.Update(uint(id), req.Name, req.WalletAddressURL, req.ImageURL, req.Bio, req.Location, req.Specialty, req.CraftType, req.Tags)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, artisan)
}

func (h *ArtisanHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.svc.Delete(uint(id)); err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}

func (h *ArtisanHandler) GetPublic(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	artisan, err := h.svc.Get(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "artisan not found"})
		return
	}

	if !artisan.IsActive {
		c.JSON(http.StatusNotFound, gin.H{"error": "artisan not found"})
		return
	}

	c.JSON(http.StatusOK, artisan)
}

func (h *ArtisanHandler) ToggleActive(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	cascade := c.Query("cascade") == "true"

	artisan, err := h.svc.ToggleActive(uint(id), cascade)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, artisan)
}
