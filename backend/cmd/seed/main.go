package main

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"github.com/whoAngeel/openpayments/internal/gallery/service"
	gormPostgres "gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormLogger "gorm.io/gorm/logger"
)

func main() {
	_ = godotenv.Load()
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		fmt.Println("DATABASE_URL not set")
		os.Exit(1)
	}

	db, err := gorm.Open(gormPostgres.New(gormPostgres.Config{
		DSN:                  dsn,
		PreferSimpleProtocol: true,
	}), &gorm.Config{
		Logger: gormLogger.Default.LogMode(gormLogger.Silent),
	})
	if err != nil {
		fmt.Println("db connection:", err)
		os.Exit(1)
	}

	if err := db.AutoMigrate(
		&model.User{},
		&model.Gallery{},
		&model.Artisan{},
		&model.Product{},
		&model.Commission{},
	); err != nil {
		fmt.Println("migration:", err)
		os.Exit(1)
	}

	authSvc := service.NewAuthService(db, "dev-secret-change-in-production")
	gallerySvc := service.NewGalleryService(db)
	artisanSvc := service.NewArtisanService(db)
	productSvc := service.NewProductService(db)

	user, _, err := authSvc.Register("gallery@art.com", "password123", "Gallery Owner")
	if err != nil {
		fmt.Println("register user:", err)
	}

	gallery, err := gallerySvc.CreateGallery(user.ID, "Galería Oaxaca")
	if err != nil {
		fmt.Println("create gallery:", err)
	}
	fmt.Printf("Created gallery: %s (ID=%d, owner=%s)\n", gallery.Name, gallery.ID, user.Email)

	_, err = gallerySvc.SetCommission(gallery.ID, user.ID, 3000)
	if err != nil {
		fmt.Println("set commission:", err)
	}
	fmt.Println("Commission: 30%")

	artisan1, _ := artisanSvc.Create("María Hernández", "https://ilp.interledger-test.dev/angeel")
	artisan2, _ := artisanSvc.Create("Juan López", "https://ilp.interledger-test.dev/angeel")
	fmt.Printf("Artisans: %s, %s\n", artisan1.Name, artisan2.Name)

	gallerySvc.AddArtisan(gallery.ID, user.ID, artisan1.ID)
	gallerySvc.AddArtisan(gallery.ID, user.ID, artisan2.ID)
	fmt.Println("Artisans linked to gallery")

	_, _ = productSvc.Create(artisan1.ID, "Alejibre de madera", "USD", 5000, 2)
	_, _ = productSvc.Create(artisan1.ID, "Máscara tradicional", "USD", 3500, 2)
	_, _ = productSvc.Create(artisan2.ID, "Tapete tejido", "USD", 8000, 2)

	fmt.Println("Products: Alebrije ($50.00), Máscara ($35.00), Tapete ($80.00)")
	fmt.Println("\nSeed complete.")
}
