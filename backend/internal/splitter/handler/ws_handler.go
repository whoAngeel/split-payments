package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func WSConnect(c *gin.Context) {
	sessionID := c.Param("session_id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "missing session_id",
		})
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	hub.Add(sessionID, conn)

	go func() {
		defer conn.Close()
		defer hub.Remove(sessionID, conn)

		for {
			_, _, err := conn.ReadMessage()
			if err != nil {
				break
			}
		}
	}()
}
