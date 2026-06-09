package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/charmbracelet/log"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/whoAngeel/openpayments/internal/splitter/service"
)

type SplitHandler struct {
	log *log.Logger
	svc *service.PaymentService
}

func NewSplitHandler(logger *log.Logger, svc *service.PaymentService) *SplitHandler {
	return &SplitHandler{logger, svc}
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

func (h *SplitHandler) GetWallet(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()
	// wallet := c.Param("wallet")
	wallet := c.Query("url")
	walletInfo, err := h.svc.GetWalletInfo(ctx, wallet)
	if err != nil {
		h.log.Fatal("Error handling wallet info", "error", err)
	}

	c.JSON(http.StatusAccepted, gin.H{"wallet": walletInfo})
}
