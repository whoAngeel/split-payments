package handler

import (
	"net/http"

	"github.com/charmbracelet/log"
	"github.com/gin-gonic/gin"
)

type HealthHandler struct {
	log *log.Logger
}

func NewHealthHandler(logger *log.Logger) *HealthHandler {
	return &HealthHandler{logger}
}

func (h *HealthHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "OK"})
}
