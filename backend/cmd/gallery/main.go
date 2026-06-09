package main

import (
	"os"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/handler"
	"github.com/whoAngeel/openpayments/internal/shared/logging"
)

func main() {
	logger := logging.New(logging.Config{
		Service: "gallery",
		Level:   os.Getenv("LOG_LEVEL"),
		Format:  os.Getenv("LOG_FORMAT"),
	})

	router := gin.New()
	router.Use(logging.GinMiddleware(logger))
	router.Use(gin.Recovery())

	router.GET("/health", handler.Health)

	logger.Info("starting server", "port", 4000)
	if err := router.Run(":4000"); err != nil {
		logger.Fatal("server failed", "err", err)
	}
}
