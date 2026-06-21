package service

import (
	"testing"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
)

func TestGalleryService_Create(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "owner@test.com", PasswordHash: "x", Name: "Owner", Role: "gallery_admin"}
	db.Create(&user)

	svc := NewGalleryService(db)
	gallery, err := svc.CreateGallery(user.ID, "My Gallery")
	if err != nil {
		t.Fatalf("create gallery failed: %v", err)
	}

	if gallery.Name != "My Gallery" {
		t.Errorf("expected My Gallery, got %s", gallery.Name)
	}
	if gallery.UserID != user.ID {
		t.Errorf("expected userID %d, got %d", user.ID, gallery.UserID)
	}
}

func TestGalleryService_CreateAlreadyHasGallery(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "owner@test.com", PasswordHash: "x", Name: "Owner", Role: "gallery_admin"}
	db.Create(&user)

	svc := NewGalleryService(db)
	_, err := svc.CreateGallery(user.ID, "First")
	if err != nil {
		t.Fatalf("first create failed: %v", err)
	}

	_, err = svc.CreateGallery(user.ID, "Second")
	if err == nil {
		t.Fatal("expected error when user already has a gallery")
	}
}

func TestGalleryService_CreateBuyerCannotCreate(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "buyer@test.com", PasswordHash: "x", Name: "Buyer", Role: "buyer"}
	db.Create(&user)

	svc := NewGalleryService(db)
	_, err := svc.CreateGallery(user.ID, "Gallery")
	if err == nil {
		t.Fatal("expected error when buyer creates gallery")
	}
}

func TestGalleryService_List(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "list@test.com", PasswordHash: "x", Name: "User", Role: "gallery_admin"}
	db.Create(&user)

	svc := NewGalleryService(db)
	_, _ = svc.CreateGallery(user.ID, "G1")

	galleries, err := svc.ListGalleries(user.ID)
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}
	if len(galleries) != 1 {
		t.Errorf("expected 1, got %d", len(galleries))
	}
}

func TestGalleryService_ListOnlyOwn(t *testing.T) {
	db := setupTestDB(t)
	user1 := model.User{Email: "u1@test.com", PasswordHash: "x", Name: "U1", Role: "gallery_admin"}
	db.Create(&user1)
	user2 := model.User{Email: "u2@test.com", PasswordHash: "x", Name: "U2", Role: "gallery_admin"}
	db.Create(&user2)

	svc := NewGalleryService(db)
	_, _ = svc.CreateGallery(user1.ID, "G1")
	_, _ = svc.CreateGallery(user2.ID, "G2")

	galleries, err := svc.ListGalleries(user1.ID)
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}
	if len(galleries) != 1 {
		t.Errorf("user1 should see 1 gallery, got %d", len(galleries))
	}
	if galleries[0].Name != "G1" {
		t.Errorf("expected G1, got %s", galleries[0].Name)
	}
}

func TestGalleryService_SetCommission(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "comm@test.com", PasswordHash: "x", Name: "User", Role: "gallery_admin"}
	db.Create(&user)

	svc := NewGalleryService(db)
	gallery, _ := svc.CreateGallery(user.ID, "G")

	commission, err := svc.SetCommission(gallery.ID, user.ID, 3000)
	if err != nil {
		t.Fatalf("set commission failed: %v", err)
	}
	if commission.Rate != 3000 {
		t.Errorf("expected rate 3000, got %d", commission.Rate)
	}

	commission2, err := svc.SetCommission(gallery.ID, user.ID, 1500)
	if err != nil {
		t.Fatalf("update commission failed: %v", err)
	}
	if commission2.Rate != 1500 {
		t.Errorf("expected updated rate 1500, got %d", commission2.Rate)
	}
}

func TestGalleryService_SetCommissionNotOwner(t *testing.T) {
	db := setupTestDB(t)
	user1 := model.User{Email: "owner@test.com", PasswordHash: "x", Name: "Owner", Role: "gallery_admin"}
	db.Create(&user1)
	user2 := model.User{Email: "hacker@test.com", PasswordHash: "x", Name: "Hacker", Role: "gallery_admin"}
	db.Create(&user2)

	svc := NewGalleryService(db)
	gallery, _ := svc.CreateGallery(user1.ID, "G")

	_, err := svc.SetCommission(gallery.ID, user2.ID, 9999)
	if err == nil {
		t.Fatal("hacker should not be able to set commission on another user's gallery")
	}
}

func TestGalleryService_AddRemoveArtisan(t *testing.T) {
	db := setupTestDB(t)
	user := model.User{Email: "g@test.com", PasswordHash: "x", Name: "U", Role: "gallery_admin"}
	db.Create(&user)

	artisanSvc := NewArtisanService(db)
	artisan, _ := artisanSvc.Create("Artisan", "https://w.example/a", "", "", "", "", "", "")

	svc := NewGalleryService(db)
	gallery, _ := svc.CreateGallery(user.ID, "G")

	if err := svc.AddArtisan(gallery.ID, user.ID, artisan.ID); err != nil {
		t.Fatalf("add artisan failed: %v", err)
	}

	result, err := svc.GetGallery(gallery.ID, user.ID)
	if err != nil {
		t.Fatalf("get gallery failed: %v", err)
	}
	if len(result.Artisans) != 1 {
		t.Errorf("expected 1 artisan, got %d", len(result.Artisans))
	}

	if err := svc.RemoveArtisan(gallery.ID, user.ID, artisan.ID); err != nil {
		t.Fatalf("remove artisan failed: %v", err)
	}

	result, _ = svc.GetGallery(gallery.ID, user.ID)
	if len(result.Artisans) != 0 {
		t.Errorf("expected 0 artisans after remove, got %d", len(result.Artisans))
	}
}
