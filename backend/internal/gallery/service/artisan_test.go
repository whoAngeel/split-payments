package service

import (
	"testing"
)

func TestArtisanService_Create(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	artisan, err := svc.Create("Artisan 1", "https://wallet.example/artisan1", "", "", "", "", "", "")
	if err != nil {
		t.Fatalf("create artisan failed: %v", err)
	}

	if artisan.ID != 1 {
		t.Errorf("expected ID 1, got %d", artisan.ID)
	}
	if artisan.Name != "Artisan 1" {
		t.Errorf("expected Artisan 1, got %s", artisan.Name)
	}
}

func TestArtisanService_List(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	_, _ = svc.Create("A", "https://w.example/a", "", "", "", "", "", "")
	_, _ = svc.Create("B", "https://w.example/b", "", "", "", "", "", "")

	artisans, err := svc.List()
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}

	if len(artisans) != 2 {
		t.Errorf("expected 2 artisans, got %d", len(artisans))
	}
}

func TestArtisanService_Get(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	created, _ := svc.Create("Artisan X", "https://w.example/x", "", "", "", "", "", "")

	artisan, err := svc.Get(created.ID)
	if err != nil {
		t.Fatalf("get failed: %v", err)
	}
	if artisan.Name != "Artisan X" {
		t.Errorf("expected Artisan X, got %s", artisan.Name)
	}
}

func TestArtisanService_GetNotFound(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	_, err := svc.Get(999)
	if err == nil {
		t.Fatal("expected error for non-existent artisan")
	}
}
