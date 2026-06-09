package handler

import (
	"net/http"

	"github.com/charmbracelet/log"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SplitHandler struct {
	log *log.Logger
}

func NewSplitHandler(logger *log.Logger) *SplitHandler {
	return &SplitHandler{logger}
}

type SplitRequest struct {
	SenderWallet string      `json:"sender_wallet" binding:"required"`
	Shares       []ShareItem `json:"shares" binding:"required,min=1"`
}

type ShareItem struct {
	Wallet string `json:"wallet" binding:"required"`
	Amount string `json:"amount" binding:"required"`
}

type SplitResponse struct {
	SessionID string `json:"session_id"`
	Status    string `json:"status"`
}

func (h *SplitHandler) Split(c *gin.Context) {
	var req SplitRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid split request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	sessionID := uuid.New().String()
	h.log.Info("split session created", "session_id", sessionID, "shares", len(req.Shares))
	c.JSON(http.StatusAccepted, SplitResponse{SessionID: sessionID, Status: "pending"})
}
