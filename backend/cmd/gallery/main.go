package main

import (
	"os"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/config"
	"github.com/whoAngeel/openpayments/internal/gallery/handler"
	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"github.com/whoAngeel/openpayments/internal/shared/logging"
	gormPostgres "gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormLogger "gorm.io/gorm/logger"
)

func main() {
	logger := logging.New(logging.Config{
		Service: "gallery",
		Level:   os.Getenv("LOG_LEVEL"),
		Format:  os.Getenv("LOG_FORMAT"),
	})

	cfg := config.Load()

	db, err := gorm.Open(gormPostgres.New(gormPostgres.Config{
		DSN:                  cfg.DatabaseURL,
		PreferSimpleProtocol: true,
	}), &gorm.Config{
		Logger: gormLogger.Default.LogMode(gormLogger.Silent),
	})
	if err != nil {
		logger.Fatal("db connection", "err", err)
	}

	if err := db.AutoMigrate(
		&model.User{},
		&model.Gallery{},
		&model.Artisan{},
		&model.Product{},
		&model.Commission{},
	); err != nil {
		logger.Fatal("migration", "err", err)
	}

	logger.Info("database migrated")

	router := gin.New()
	router.Use(logging.GinMiddleware(logger))
	router.Use(gin.Recovery())

	router.GET("/health", handler.Health)

	logger.Info("starting server", "port", 4000)
	if err := router.Run(":4000"); err != nil {
		logger.Fatal("server failed", "err", err)
	}
}
