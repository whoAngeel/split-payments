package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type PaymentHandler struct {
	svc *service.PaymentService
}

func NewPaymentHandler(svc *service.PaymentService) *PaymentHandler {
	return &PaymentHandler{svc: svc}
}

type savePaymentRequest struct {
	SessionID string `json:"session_id" binding:"required"`
	ProductID uint   `json:"product_id" binding:"required"`
	BuyerID   uint   `json:"buyer_id" binding:"required"`
}

func (h *PaymentHandler) Save(c *gin.Context) {
	var req savePaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	payment, err := h.svc.Save(service.SavePaymentInput{
		SessionID: req.SessionID,
		BuyerID:   req.BuyerID,
		ProductID: req.ProductID,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, payment)
}
func (h *PaymentHandler) Complete(c *gin.Context) {
	var req struct {
		SessionID string `json:"session_id" binding:"required"`
		Status    string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	payment, err := h.svc.Complete(req.SessionID, req.Status)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, payment)
}
func (h *PaymentHandler) ListByGallery(c *gin.Context) {
	galleryID, err := strconv.ParseUint(c.Param("gallery_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid gallery id"})
		return
	}
	payments, summary, err := h.svc.ListByGallery(uint(galleryID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"summary": summary, "payments": payments})
}

func (h *PaymentHandler) List(c *gin.Context) {
	userIDStr := c.Query("user_id")
	if userIDStr == "" {
		userID := c.GetUint("userID")
		userIDStr = strconv.FormatUint(uint64(userID), 10)
	}
	userID, _ := strconv.ParseUint(userIDStr, 10, 64)
	payments, err := h.svc.ListByUser(uint(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, payments)
}
