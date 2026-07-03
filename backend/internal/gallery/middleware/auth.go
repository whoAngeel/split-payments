package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

func AuthRequired(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
			c.Abort()
			return
		}

		token := strings.TrimPrefix(header, "Bearer ")
		userID, role, galleryID, err := svc.ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}

		c.Set("userID", userID)
		c.Set("role", role)
		c.Set("galleryID", galleryID)
		c.Next()
	}
}
