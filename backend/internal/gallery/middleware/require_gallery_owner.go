package middleware

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func RequireGalleryOwner() gin.HandlerFunc {
	return func(c *gin.Context) {
		galleryID, err := strconv.ParseUint(c.Param("gallery_id"), 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid gallery_id"})
			c.Abort()
			return
		}

		tokenGalleryID := c.GetUint("galleryID")

		if uint(galleryID) != tokenGalleryID {
			c.JSON(http.StatusForbidden, gin.H{"error": "you do not own this gallery"})
			c.Abort()
			return
		}

		c.Next()
	}
}
