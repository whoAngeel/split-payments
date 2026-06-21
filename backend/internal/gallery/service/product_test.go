package service

import (
	"testing"
)

func TestProductService_Create(t *testing.T) {
	db := setupTestDB(t)

	artisan, _ := NewArtisanService(db).Create("Artisan", "https://w.example/a", "", "", "", "", "", "")

	svc := NewProductService(db)
	product, err := svc.Create(artisan.ID, "Product 1", "USD", 10000, 2, 0, "")
	if err != nil {
		t.Fatalf("create product failed: %v", err)
	}

	if product.BasePrice != 10000 {
		t.Errorf("expected 10000, got %d", product.BasePrice)
	}
	if product.AssetCode != "USD" {
		t.Errorf("expected USD, got %s", product.AssetCode)
	}
	if product.AssetScale != 2 {
		t.Errorf("expected scale 2, got %d", product.AssetScale)
	}
}

func TestProductService_CreateInvalidArtisan(t *testing.T) {
	db := setupTestDB(t)
	svc := NewProductService(db)

	_, err := svc.Create(999, "Product", "USD", 100, 2, 0, "")
	if err == nil {
		t.Fatal("expected foreign key error, got nil")
	}
}

func TestProductService_GetByArtisan(t *testing.T) {
	db := setupTestDB(t)

	artisan1, _ := NewArtisanService(db).Create("A1", "https://w.example/a1", "", "", "", "", "", "")
	artisan2, _ := NewArtisanService(db).Create("A2", "https://w.example/a2", "", "", "", "", "", "")

	svc := NewProductService(db)
	_, _ = svc.Create(artisan1.ID, "P1", "USD", 100, 2, 0, "")
	_, _ = svc.Create(artisan1.ID, "P2", "USD", 200, 2, 0, "")
	_, _ = svc.Create(artisan2.ID, "P3", "USD", 300, 2, 0, "")

	products, err := svc.GetByArtisan(artisan1.ID)
	if err != nil {
		t.Fatalf("get by artisan failed: %v", err)
	}
	if len(products) != 2 {
		t.Errorf("expected 2 products, got %d", len(products))
	}
}

func TestProductService_Delete(t *testing.T) {
	db := setupTestDB(t)
	artisan, _ := NewArtisanService(db).Create("A", "https://w.example/a", "", "", "", "", "", "")
	svc := NewProductService(db)

	product, _ := svc.Create(artisan.ID, "P", "USD", 100, 2, 0, "")

	if err := svc.Delete(product.ID); err != nil {
		t.Fatalf("delete failed: %v", err)
	}

	products, _ := svc.GetByArtisan(artisan.ID)
	if len(products) != 0 {
		t.Errorf("expected 0 products after delete, got %d", len(products))
	}
}
