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
		&model.ProductDetail{},
		&model.ProductImage{},
		&model.Commission{},
		&model.Favorite{},
		&model.Payment{},
	); err != nil {
		logger.Fatal("migration", "err", err)
	}

	logger.Info("database migrated")

	authSvc := service.NewAuthService(db, cfg.JWTSecret, cfg.InviteCode)
	gallerySvc := service.NewGalleryService(db)
	artisanSvc := service.NewArtisanService(db)
	productSvc := service.NewProductService(db)
	favoriteSvc := service.NewFavoriteService(db)
	checkoutSvc := service.NewCheckoutService(db, cfg.SplitterURL, cfg.SplitterAPIKey)
	paymentSvc := service.NewPaymentService(db)

	uploadSvc, err := service.NewUploadService(cfg.MinioEndpoint, cfg.MinioAccessKey, cfg.MinioSecretKey, cfg.MinioBucket)
	if err != nil {
		logger.Fatal("upload service", "err", err)
	}

	authHandler := handler.NewAuthHandler(authSvc)
	galleryHandler := handler.NewGalleryHandler(gallerySvc, authSvc)
	artisanHandler := handler.NewArtisanHandler(artisanSvc, gallerySvc)
	productHandler := handler.NewProductHandler(productSvc, favoriteSvc)
	favoriteHandler := handler.NewFavoriteHandler(favoriteSvc)
	checkoutHandler := handler.NewCheckoutHandler(checkoutSvc)
	paymentHandler := handler.NewPaymentHandler(paymentSvc)
	uploadHandler := handler.NewUploadHandler(uploadSvc)
	imageProxy := handler.NewImageProxyHandler(uploadSvc.MinioClient(), uploadSvc.MinioBucket())
	productImageHandler := handler.NewProductImageHandler(db)

	router := gin.New()
	router.Use(logging.GinMiddleware(logger))
	router.Use(gin.Recovery())

	// Health
	router.GET("/health", handler.Health)

	// Image proxy (public)
	router.GET("/products/*filepath", imageProxy.Serve)

	// Public auth
	auth := router.Group("/api/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}

	// Public explore
	router.GET("/api/explore/products", middleware.OptionalAuth(authSvc), productHandler.Explore)
	router.GET("/api/explore/products/:id", productHandler.GetDetail)
	router.GET("/api/artisans/:id", artisanHandler.GetPublic)

	// Protected buyer routes
	protected := router.Group("/api")
	protected.Use(middleware.AuthRequired(authSvc))
	{
		protected.GET("/auth/me", authHandler.Me)
		protected.PATCH("/auth/me", authHandler.UpdateMe)
		protected.POST("/galleries", galleryHandler.Create)
		protected.GET("/galleries", galleryHandler.List)
		protected.POST("/favorites/:product_id", favoriteHandler.Toggle)
		protected.GET("/favorites", favoriteHandler.List)
		protected.POST("/checkout", checkoutHandler.Checkout)
		protected.POST("/checkout/save", paymentHandler.Save)
		protected.POST("/checkout/complete", paymentHandler.Complete)
		protected.GET("/payments", paymentHandler.List)
		protected.POST("/upload", uploadHandler.Upload)
	}

	// Admin routes (auth + gallery ownership required)
	admin := router.Group("/api/galleries/:gallery_id")
	admin.Use(middleware.AuthRequired(authSvc))
	admin.Use(middleware.RequireGalleryOwner())
	{
		// Gallery management
		admin.GET("", galleryHandler.Get)
		admin.PUT("/commission", galleryHandler.SetCommission)
		// Artisan link/unlink (moved outside /artisans to avoid wildcard conflict)
		admin.POST("/link-artisan/:artisan_id", galleryHandler.AddArtisan)
		admin.DELETE("/link-artisan/:artisan_id", galleryHandler.RemoveArtisan)

		// Artisans
		admin.POST("/artisans", artisanHandler.Create)
		admin.GET("/artisans", artisanHandler.List)
		admin.GET("/artisans/:id", artisanHandler.Get)
		admin.PATCH("/artisans/:id", artisanHandler.Update)
		admin.DELETE("/artisans/:id", artisanHandler.Delete)
		admin.POST("/artisans/:id/toggle-active", artisanHandler.ToggleActive)

		// Products by artisan
		admin.POST("/artisans/:id/products", productHandler.Create)
		admin.GET("/artisans/:id/products", productHandler.ListByArtisan)

		// Products flat
		admin.GET("/products", productHandler.ListByGallery)
		admin.GET("/products/:id", productHandler.GetDetailAdmin)
		admin.PATCH("/products/:id", productHandler.Update)
		admin.DELETE("/products/:id", productHandler.Delete)
		admin.POST("/products/:id/toggle-active", productHandler.ToggleActive)
		admin.GET("/products/:id/images", productImageHandler.List)
		admin.POST("/products/:id/images", productImageHandler.Add)
		admin.DELETE("/products/:id/images/:image_id", productImageHandler.Delete)
	}

	logger.Info("starting server", "port", 4000)
	if err := router.Run(":4000"); err != nil {
		logger.Fatal("server failed", "err", err)
	}
}
