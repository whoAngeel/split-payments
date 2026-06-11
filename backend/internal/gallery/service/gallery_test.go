package service

import (
	"testing"
)

func TestGalleryService_Create(t *testing.T) {
	db := setupTestDB(t)
	authSvc := NewAuthService(db, "test-secret")
	user, _, _ := authSvc.Register("owner@test.com", "password123", "Owner")

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

func TestGalleryService_List(t *testing.T) {
	db := setupTestDB(t)
	authSvc := NewAuthService(db, "test-secret")
	user, _, _ := authSvc.Register("list@test.com", "password123", "User")

	svc := NewGalleryService(db)
	_, _ = svc.CreateGallery(user.ID, "G1")
	_, _ = svc.CreateGallery(user.ID, "G2")

	galleries, err := svc.ListGalleries(user.ID)
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}
	if len(galleries) != 2 {
		t.Errorf("expected 2, got %d", len(galleries))
	}
}

func TestGalleryService_ListOnlyOwn(t *testing.T) {
	db := setupTestDB(t)
	authSvc := NewAuthService(db, "test-secret")
	user1, _, _ := authSvc.Register("u1@test.com", "password123", "U1")
	user2, _, _ := authSvc.Register("u2@test.com", "password123", "U2")

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
	authSvc := NewAuthService(db, "test-secret")
	user, _, _ := authSvc.Register("comm@test.com", "password123", "User")

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
	authSvc := NewAuthService(db, "test-secret")
	user1, _, _ := authSvc.Register("owner@test.com", "password123", "Owner")
	user2, _, _ := authSvc.Register("hacker@test.com", "password123", "Hacker")

	svc := NewGalleryService(db)
	gallery, _ := svc.CreateGallery(user1.ID, "G")

	_, err := svc.SetCommission(gallery.ID, user2.ID, 9999)
	if err == nil {
		t.Fatal("hacker should not be able to set commission on another user's gallery")
	}
}

func TestGalleryService_AddRemoveArtisan(t *testing.T) {
	db := setupTestDB(t)
	authSvc := NewAuthService(db, "test-secret")
	user, _, _ := authSvc.Register("g@test.com", "password123", "U")

	artisanSvc := NewArtisanService(db)
	artisan, _ := artisanSvc.Create("Artisan", "https://w.example/a")

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
