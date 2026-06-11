package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type GalleryHandler struct {
	svc *service.GalleryService
}

func NewGalleryHandler(svc *service.GalleryService) *GalleryHandler {
	return &GalleryHandler{svc: svc}
}

type createGalleryRequest struct {
	Name string `json:"name" binding:"required"`
}

type setCommissionRequest struct {
	Rate int `json:"rate" binding:"required,min=0,max=10000"`
}

func (h *GalleryHandler) Create(c *gin.Context) {
	userID := c.GetUint("userID")

	var req createGalleryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	gallery, err := h.svc.CreateGallery(userID, req.Name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gallery)
}

func (h *GalleryHandler) List(c *gin.Context) {
	userID := c.GetUint("userID")

	galleries, err := h.svc.ListGalleries(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, galleries)
}

func (h *GalleryHandler) SetCommission(c *gin.Context) {
	userID := c.GetUint("userID")
	galleryID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var req setCommissionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	commission, err := h.svc.SetCommission(uint(galleryID), userID, req.Rate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, commission)
}

func (h *GalleryHandler) AddArtisan(c *gin.Context) {
	userID := c.GetUint("userID")
	galleryID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid gallery id"})
		return
	}
	artisanID, err := strconv.ParseUint(c.Param("artisan_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid artisan id"})
		return
	}

	if err := h.svc.AddArtisan(uint(galleryID), userID, uint(artisanID)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "added"})
}
