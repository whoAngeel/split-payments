package logging

import (
	"time"

	"github.com/charmbracelet/log"
	"github.com/gin-gonic/gin"
)

func GinMiddleware(logger *log.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		if raw := c.Request.URL.RawQuery; raw != "" {
			path += "?" + raw
		}

		c.Next()

		entry := logger.With(
			"method", c.Request.Method,
			"path", path,
			"status", c.Writer.Status(),
			"latency", time.Since(start),
			"client_ip", c.ClientIP(),
		)

		if len(c.Errors) > 0 {
			entry.Error(c.Errors.String())
			return
		}

		switch status := c.Writer.Status(); {
		case status >= 500:
			entry.Error("request")
		case status >= 400:
			entry.Warn("request")
		default:
			entry.Info("request")
		}
	}
}
