package main

import (
	"os"

	"github.com/gin-gonic/gin"
	openpayments "github.com/interledger/open-payments-go"
	"github.com/whoAngeel/openpayments/internal/shared/logging"
	"github.com/whoAngeel/openpayments/internal/splitter/config"
	"github.com/whoAngeel/openpayments/internal/splitter/handler"
	"github.com/whoAngeel/openpayments/internal/splitter/middleware"
	"github.com/whoAngeel/openpayments/internal/splitter/service"
)

func main() {
	logger := logging.New(logging.Config{
		Service: "splitter",
		Level:   os.Getenv("LOG_LEVEL"),
		Format:  os.Getenv("LOG_FORMAT"),
	})

	cfg := config.Load()

	logger.Debug("cfg", "path", cfg.PrivateKeyBase64)

	router := gin.New()
	router.Use(logging.GinMiddleware(logger))
	router.Use(gin.Recovery())

	opClient, err := openpayments.NewAuthenticatedClient(cfg.WalletAddressURL, cfg.PrivateKeyBase64, cfg.KeyID)
	if err != nil {
		logger.Fatal("op client", "err", err)
	}

	paymentService := service.NewPaymentService(opClient, logger, cfg.PublicURL)

	healthHandler := handler.NewHealthHandler(logger)
	splitHandler := handler.NewSplitHandler(logger, paymentService)

	router.GET("/health", healthHandler.Health)
	router.GET("/ws/:session_id", handler.WSConnect)
	router.GET("/split/callback", splitHandler.SplitCallback)

	api := router.Group("/")
	api.Use(middleware.APIKey(cfg.APIKey))
	{
		api.POST("/split", splitHandler.Split)
		api.POST("/incoming-payment", splitHandler.CreateIncomingPayment)
		api.POST("/quote", splitHandler.CreateQuote)
		api.POST("/outgoing-grant", splitHandler.RequestOutgoingPaymentGrant)
		api.POST("/outgoing-payment", splitHandler.CreateOutgoingPayment)
		api.GET("/wallet", splitHandler.GetWallet)
	}

	logger.Info("starting server", "port", 4001)
	if err := router.Run(":4001"); err != nil {
		logger.Fatal("server failed", "err", err)
	}
}
