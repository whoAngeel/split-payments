package service

import (
	"testing"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
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

func TestArtisanService_CreateWithAllFields(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	artisan, err := svc.Create(
		"Maria", "https://wallet.example/maria",
		"https://img.example/maria.jpg", "Bio de Maria",
		"Oaxaca, México", "Textiles", "Bordado a mano", "algodón, tintes naturales",
	)
	if err != nil {
		t.Fatalf("create failed: %v", err)
	}

	if artisan.Name != "Maria" {
		t.Errorf("name: expected Maria, got %s", artisan.Name)
	}
	if artisan.Location != "Oaxaca, México" {
		t.Errorf("location: expected Oaxaca, got %s", artisan.Location)
	}
	if artisan.Specialty != "Textiles" {
		t.Errorf("specialty: expected Textiles, got %s", artisan.Specialty)
	}
	if artisan.CraftType != "Bordado a mano" {
		t.Errorf("craft_type: expected Bordado, got %s", artisan.CraftType)
	}
	if artisan.Bio != "Bio de Maria" {
		t.Errorf("bio: expected Bio de Maria, got %s", artisan.Bio)
	}
	if artisan.ImageURL != "https://img.example/maria.jpg" {
		t.Errorf("image_url: expected url, got %s", artisan.ImageURL)
	}
	if artisan.Tags != "algodón, tintes naturales" {
		t.Errorf("tags: expected tags, got %s", artisan.Tags)
	}

	// Verify persisted in DB
	var dbArtisan model.Artisan
	if err := db.First(&dbArtisan, artisan.ID).Error; err != nil {
		t.Fatalf("fetch from db failed: %v", err)
	}
	if dbArtisan.Location != "Oaxaca, México" {
		t.Errorf("db location: expected Oaxaca, got %s", dbArtisan.Location)
	}
	if dbArtisan.Tags != "algodón, tintes naturales" {
		t.Errorf("db tags: expected tags, got %s", dbArtisan.Tags)
	}
}

func TestArtisanService_UpdatePartialFields(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	created, _ := svc.Create(
		"Juan", "https://wallet.example/juan",
		"https://img.example/juan.jpg", "Bio original",
		"Puebla", "Cerámica", "Alfarería", "barro, esmalte",
	)

	// Update only name and wallet — other fields should remain
	updated, err := svc.Update(created.ID, "Juan Editado", "https://wallet.example/juan-new", "", "", "", "", "", "")
	if err != nil {
		t.Fatalf("update failed: %v", err)
	}

	if updated.Name != "Juan Editado" {
		t.Errorf("name not updated: got %s", updated.Name)
	}
	if updated.WalletAddressURL != "https://wallet.example/juan-new" {
		t.Errorf("wallet not updated: got %s", updated.WalletAddressURL)
	}

	// Fields NOT included in update should remain unchanged
	if updated.ImageURL != "https://img.example/juan.jpg" {
		t.Errorf("image_url was overwritten: got %s", updated.ImageURL)
	}
	if updated.Bio != "Bio original" {
		t.Errorf("bio was overwritten: got %s", updated.Bio)
	}
	if updated.Location != "Puebla" {
		t.Errorf("location was overwritten: got %s", updated.Location)
	}
	if updated.Specialty != "Cerámica" {
		t.Errorf("specialty was overwritten: got %s", updated.Specialty)
	}
	if updated.CraftType != "Alfarería" {
		t.Errorf("craft_type was overwritten: got %s", updated.CraftType)
	}
	if updated.Tags != "barro, esmalte" {
		t.Errorf("tags were overwritten: got %s", updated.Tags)
	}
}

func TestArtisanService_UpdateAllFields(t *testing.T) {
	db := setupTestDB(t)
	svc := NewArtisanService(db)

	created, _ := svc.Create("A", "w", "img", "bio", "loc", "spec", "craft", "tags")

	updated, err := svc.Update(created.ID, "B", "w2", "img2", "bio2", "loc2", "spec2", "craft2", "tags2")
	if err != nil {
		t.Fatalf("update failed: %v", err)
	}

	if updated.Name != "B" || updated.Location != "loc2" || updated.Tags != "tags2" {
		t.Errorf("all fields should update: got name=%s loc=%s tags=%s", updated.Name, updated.Location, updated.Tags)
	}
}
