package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func APIKey(apiKey string) gin.HandlerFunc {
	if apiKey == "" {
		return func(c *gin.Context) { c.Next() }
	}

	return func(c *gin.Context) {
		key := c.GetHeader("Authorization")
		expected := "Bearer " + apiKey

		if key != expected {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid api key"})
			c.Abort()
			return
		}

		c.Next()
	}
}
