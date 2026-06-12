package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type CheckoutHandler struct {
	svc *service.CheckoutService
}

func NewCheckoutHandler(svc *service.CheckoutService) *CheckoutHandler {
	return &CheckoutHandler{svc: svc}
}

type checkoutRequest struct {
	ProductID   uint   `json:"product_id" binding:"required"`
	BuyerWallet string `json:"buyer_wallet" binding:"required"`
}

func (h *CheckoutHandler) Checkout(c *gin.Context) {
	var req checkoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.svc.Checkout(req.BuyerWallet, req.ProductID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}
