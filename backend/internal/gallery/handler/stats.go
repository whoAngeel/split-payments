package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type StatsHandler struct {
	svc *service.StatsService
}

func NewStatsHandler(svc *service.StatsService) *StatsHandler {
	return &StatsHandler{svc: svc}
}

func (h *StatsHandler) Dashboard(c *gin.Context) {
	stats, err := h.svc.GetDashboardStats(c.GetUint("galleryID"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *StatsHandler) Artisans(c *gin.Context) {
	stats, err := h.svc.GetArtisanStats(c.GetUint("galleryID"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *StatsHandler) Products(c *gin.Context) {
	stats, err := h.svc.GetProductStats(c.GetUint("galleryID"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}
