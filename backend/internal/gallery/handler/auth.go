package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

type AuthHandler struct {
	svc *service.AuthService
}

func NewAuthHandler(svc *service.AuthService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

type registerRequest struct {
	Email            string `json:"email" binding:"required,email"`
	Password         string `json:"password" binding:"required,min=8"`
	Name             string `json:"name" binding:"required"`
	WalletAddressURL string `json:"wallet_address_url"`
	Role             string `json:"role"`
	GalleryName      string `json:"gallery_name"`
	InviteCode       string `json:"invite_code"`
}

type loginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, token, err := h.svc.Register(req.Email, req.Password, req.Name, req.WalletAddressURL, req.Role, req.GalleryName, req.InviteCode)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	_, _, galleryID, _ := h.svc.ValidateToken(token)

	c.JSON(http.StatusCreated, gin.H{
		"user":       user,
		"token":      token,
		"gallery_id": galleryID,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, token, err := h.svc.Login(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	_, _, galleryID, _ := h.svc.ValidateToken(token)

	c.JSON(http.StatusOK, gin.H{
		"user":       user,
		"token":      token,
		"gallery_id": galleryID,
	})
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID := c.GetUint("userID")
	galleryID := c.GetUint("galleryID")

	user, err := h.svc.GetUser(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"user":       user,
		"gallery_id": galleryID,
	})
}

type updateMeRequest struct {
	Name             string `json:"name"`
	WalletAddressURL string `json:"wallet_address_url"`
}

func (h *AuthHandler) UpdateMe(c *gin.Context) {
	userID := c.GetUint("userID")

	var req updateMeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.svc.GetUser(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	if req.Name != "" {
		user.Name = req.Name
	}
	user.WalletAddressURL = req.WalletAddressURL

	if err := h.svc.UpdateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}
