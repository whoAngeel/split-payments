package main

import (
	"os"

	"github.com/gin-gonic/gin"
	"github.com/whoAngeel/openpayments/internal/gallery/config"
	"github.com/whoAngeel/openpayments/internal/gallery/handler"
	"github.com/whoAngeel/openpayments/internal/gallery/middleware"
	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
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

	authSvc := service.NewAuthService(db, cfg.JWTSecret)
	gallerySvc := service.NewGalleryService(db)
	artisanSvc := service.NewArtisanService(db)
	productSvc := service.NewProductService(db)

	authHandler := handler.NewAuthHandler(authSvc)
	galleryHandler := handler.NewGalleryHandler(gallerySvc)
	artisanHandler := handler.NewArtisanHandler(artisanSvc)
	productHandler := handler.NewProductHandler(productSvc)

	router := gin.New()
	router.Use(logging.GinMiddleware(logger))
	router.Use(gin.Recovery())

	router.GET("/health", handler.Health)

	auth := router.Group("/api/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}

	protected := router.Group("/api")
	protected.Use(middleware.AuthRequired(authSvc))
	{
		protected.POST("/galleries", galleryHandler.Create)
		protected.GET("/galleries", galleryHandler.List)
		protected.PUT("/galleries/:id/commission", galleryHandler.SetCommission)
		protected.POST("/galleries/:id/artisans/:artisan_id", galleryHandler.AddArtisan)

		protected.POST("/artisans", artisanHandler.Create)
		protected.GET("/artisans", artisanHandler.List)
		protected.GET("/artisans/:id", artisanHandler.Get)

		protected.POST("/artisans/:artisan_id/products", productHandler.Create)
		protected.GET("/artisans/:artisan_id/products", productHandler.ListByArtisan)
		protected.DELETE("/products/:id", productHandler.Delete)
	}

	logger.Info("starting server", "port", 4000)
	if err := router.Run(":4000"); err != nil {
		logger.Fatal("server failed", "err", err)
	}
}
