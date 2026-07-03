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
		&model.Favorite{},
	); err != nil {
		fmt.Println("migration:", err)
		os.Exit(1)
	}

	authSvc := service.NewAuthService(db, "dev-secret-change-in-production", "")
	gallerySvc := service.NewGalleryService(db)
	artisanSvc := service.NewArtisanService(db)
	productSvc := service.NewProductService(db)

	seedUser := func(email, password, name, role, wallet string) model.User {
		var u model.User
		db.Where("email = ?", email).First(&u)
		if u.ID == 0 {
			newUser, _, err := authSvc.Register(email, password, name, "", role, "", "")
			if err != nil {
				fmt.Printf("register %s: %v\n", email, err)
				os.Exit(1)
			}
			u = *newUser
			fmt.Printf("User: %s <%s>\n", name, email)
		}
		if wallet != "" {
			db.Model(&u).Update("wallet_address_url", wallet)
		}
		return u
	}

	galleryOwner := seedUser("gallery@art.com", "password123", "Gallery Owner", "gallery_admin", "https://ilp.interledger-test.dev/angeel")
	seedUser("buyer@test.com", "password123", "Carlos Comprador", "buyer", "https://ilp.interledger-test.dev/angeel")
	fmt.Println()

	var count int64
	db.Model(&model.Gallery{}).Where("user_id = ?", galleryOwner.ID).Count(&count)
	var gallery model.Gallery
	if count == 0 {
		newGallery, gErr := gallerySvc.CreateGallery(galleryOwner.ID, "Galería Oaxaca")
		if gErr != nil {
			fmt.Println("create gallery:", gErr)
			os.Exit(1)
		}
		gallery = *newGallery
		_, _ = gallerySvc.SetCommission(gallery.ID, galleryOwner.ID, 3000)
		fmt.Println("Commission: 30%")
	} else {
		db.Where("user_id = ?", galleryOwner.ID).First(&gallery)
	}
	fmt.Printf("Gallery: %s (ID=%d, owner=%s)\n", gallery.Name, gallery.ID, galleryOwner.Email)

	var artisanCount int64
	db.Model(&model.Artisan{}).Count(&artisanCount)
	if artisanCount == 0 {
		artisan1, _ := artisanSvc.Create("María Hernández", "https://ilp.interledger-test.dev/mochi", "", "", "", "", "", "")
		artisan2, _ := artisanSvc.Create("Juan López", "https://ilp.interledger-test.dev/angeel", "", "", "", "", "", "")
		gallerySvc.AddArtisan(gallery.ID, galleryOwner.ID, artisan1.ID)
		gallerySvc.AddArtisan(gallery.ID, galleryOwner.ID, artisan2.ID)
		fmt.Printf("Artisans: %s, %s\n", artisan1.Name, artisan2.Name)

		_, _ = productSvc.Create(artisan1.ID, "Alejibre de madera", "USD", 5000, 2, 0, "https://images.unsplash.com/photo-1598214692523-866fe3f8b6bf?w=400", "", "", "", "")
		_, _ = productSvc.Create(artisan1.ID, "Máscara tradicional", "USD", 3500, 2, 0, "https://images.unsplash.com/photo-1598214692523-866fe3f8b6bf?w=400", "", "", "", "")
		_, _ = productSvc.Create(artisan2.ID, "Tapete tejido", "USD", 8000, 2, 0, "https://images.unsplash.com/photo-1598214692523-866fe3f8b6bf?w=400", "", "", "", "")
		fmt.Println("Products: Alebrije ($50.00), Máscara ($35.00), Tapete ($80.00)")
	} else {
		fmt.Println("Data already seeded, skipping.")
	}

	fmt.Println("Seed complete.")
}
