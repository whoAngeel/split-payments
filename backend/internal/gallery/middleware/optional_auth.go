package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
)

func OptionalAuth(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			c.Next()
			return
		}

		token := strings.TrimPrefix(header, "Bearer ")
		userID, role, galleryID, err := svc.ValidateToken(token)
		if err == nil {
			c.Set("userID", userID)
			c.Set("role", role)
			c.Set("galleryID", galleryID)
		}
		c.Next()
	}
}
