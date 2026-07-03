package handler

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/charmbracelet/log"
	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/shared/model"
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
	SenderWallet string        `json:"sender_wallet" binding:"required"`
	Shares       []model.Share `json:"shares" binding:"required,min=1"`
}

func (h *SplitHandler) Split(c *gin.Context) {
	var req SplitRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid split request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 30*time.Second)
	defer cancel()

	shares := make([]service.ShareInput, len(req.Shares))
	total := len(req.Shares)
	for i, s := range req.Shares {
		shares[i] = service.ShareInput{
			Wallet: s.Wallet,
			Amount: s.Amount,
			Metadata: map[string]interface{}{
				"description": fmt.Sprintf("Split payment: share %d of %d", i+1, total),
			},
		}
	}

	result, err := h.svc.InitiateSplit(ctx, req.SenderWallet, shares)
	if err != nil {
		h.log.Error("initiating split", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

func (h *SplitHandler) GetWallet(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()
	// wallet := c.Param("wallet")
	wallet := c.Query("url")
	walletInfo, err := h.svc.GetWalletInfo(ctx, wallet)
	if err != nil {
		h.log.Error("getting wallet info", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"wallet": walletInfo})
}

func (h *SplitHandler) CreateIncomingPayment(c *gin.Context) {
	var req struct {
		Wallet string `json:"wallet" binding:"required"`
		Amount string `json:"amount" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid incoming payment request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	incoming, err := h.svc.CreateIncomingPayment(ctx, req.Wallet, req.Amount, nil)
	if err != nil {
		h.log.Error("creating incoming payment", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, incoming)
}

type CreateQuoteRequest struct {
	SenderWallet      string `json:"sender_wallet" binding:"required"`
	IncomingPaymentID string `json:"incoming_payment_id" binding:"required"`
}

func (h *SplitHandler) CreateQuote(c *gin.Context) {
	var req CreateQuoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid quote request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	quote, err := h.svc.CreateQuote(ctx, req.SenderWallet, req.IncomingPaymentID)
	if err != nil {
		h.log.Error("creating quote", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, quote)
}

type OutgoingGrantRequest struct {
	SenderWallet     string `json:"sender_wallet" binding:"required"`
	TotalDebitAmount string `json:"total_debit_amount" binding:"required"`
}

func (h *SplitHandler) RequestOutgoingPaymentGrant(c *gin.Context) {
	var req OutgoingGrantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid outgoing grant request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	result, err := h.svc.RequestOutgoingPaymentGrant(ctx, req.SenderWallet, req.TotalDebitAmount)
	if err != nil {
		h.log.Error("requesting outgoing payment grant", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

func (h *SplitHandler) Callback(c *gin.Context) {
	sessionID := c.Query("session")
	interactRef := c.Query("interact_ref")
	hash := c.Query("hash")

	if sessionID == "" || interactRef == "" || hash == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing session, interact_ref or hash"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	_, err := h.svc.HandleCallback(ctx, sessionID, interactRef, hash)
	if err != nil {
		c.Redirect(http.StatusFound,
			fmt.Sprintf("openpayments://payment/complete?session_id=%s&status=failed&error=%s", sessionID, err.Error()))
		return
	}
	c.Redirect(http.StatusFound,
		fmt.Sprintf("openpayments://payment/complete?session_id=%s&status=completed", sessionID))
}

func (h *SplitHandler) SplitCallback(c *gin.Context) {
	sessionID := c.Query("session")
	interactRef := c.Query("interact_ref")
	hash := c.Query("hash")

	if sessionID == "" || interactRef == "" || hash == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing session, interact_ref or hash"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 30*time.Second)
	defer cancel()

	_, err := h.svc.HandleSplitCallback(ctx, sessionID, interactRef, hash)

	if err != nil {
		hub.Broadcast(sessionID, []byte(`{"status":"failed"}`))
		c.Redirect(http.StatusFound,
			fmt.Sprintf("openpayments://payment/complete?session_id=%s&status=failed&error=%s", sessionID, err.Error()))
		return
	}
	hub.Broadcast(sessionID, []byte(`{"status":"completed"}`))
	c.Redirect(http.StatusFound,
		fmt.Sprintf("openpayments://payment/complete?session_id=%s&status=completed", sessionID))
}

type CreateOutgoingPaymentRequest struct {
	SenderWallet string `json:"sender_wallet" binding:"required"`
	QuoteID      string `json:"quote_id" binding:"required"`
	AccessToken  string `json:"access_token" binding:"required"`
}

func (h *SplitHandler) CreateOutgoingPayment(c *gin.Context) {
	var req CreateOutgoingPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.log.Warn("invalid outgoing payment request", "err", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	outgoing, err := h.svc.CreateOutgoingPayment(ctx, req.SenderWallet, req.QuoteID, req.AccessToken)
	if err != nil {
		h.log.Error("creating outgoing payment", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, outgoing)
}
