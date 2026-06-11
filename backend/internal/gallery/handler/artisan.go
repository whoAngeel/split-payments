package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type ArtisanHandler struct {
	svc *service.ArtisanService
}

func NewArtisanHandler(svc *service.ArtisanService) *ArtisanHandler {
	return &ArtisanHandler{svc: svc}
}

type createArtisanRequest struct {
	Name             string `json:"name" binding:"required"`
	WalletAddressURL string `json:"wallet_address_url" binding:"required"`
}

func (h *ArtisanHandler) Create(c *gin.Context) {
	var req createArtisanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	artisan, err := h.svc.Create(req.Name, req.WalletAddressURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, artisan)
}

func (h *ArtisanHandler) List(c *gin.Context) {
	artisans, err := h.svc.List()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, artisans)
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
