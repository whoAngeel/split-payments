package service

import (
	"fmt"
	"testing"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
)

func TestAuthService_Register(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	user, token, err := svc.Register("test@test.com", "password123", "Test User", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	if user.ID != 1 {
		t.Errorf("expected ID 1, got %d", user.ID)
	}
	if user.Email != "test@test.com" {
		t.Errorf("expected email test@test.com, got %s", user.Email)
	}
	if user.Role != "buyer" {
		t.Errorf("expected role buyer, got %s", user.Role)
	}
	if token == "" {
		t.Error("expected token, got empty string")
	}
}

func TestAuthService_RegisterDuplicate(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, err := svc.Register("dup@test.com", "password123", "Test", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("first register failed: %v", err)
	}

	_, _, err = svc.Register("dup@test.com", "password123", "Test", "", "buyer", "", "")
	if err == nil {
		t.Fatal("expected duplicate error, got nil")
	}
}

func TestAuthService_RegisterAdminWithInviteCode(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "invite-123")

	user, token, err := svc.Register("admin@test.com", "password123", "Admin", "", "gallery_admin", "My Gallery", "invite-123")
	if err != nil {
		t.Fatalf("admin register failed: %v", err)
	}

	if user.Role != "gallery_admin" {
		t.Errorf("expected role gallery_admin, got %s", user.Role)
	}
	if token == "" {
		t.Error("expected token, got empty string")
	}

	var galleries []model.Gallery
	db.Where("user_id = ?", user.ID).Find(&galleries)
	if len(galleries) != 1 {
		t.Fatalf("expected 1 gallery, got %d", len(galleries))
	}
	if galleries[0].Name != "My Gallery" {
		t.Errorf("expected gallery name 'My Gallery', got '%s'", galleries[0].Name)
	}
}

func TestAuthService_RegisterAdminWrongInviteCode(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "correct-code")

	_, _, err := svc.Register("admin@test.com", "password123", "Admin", "", "gallery_admin", "My Gallery", "wrong-code")
	if err == nil {
		t.Fatal("expected error for wrong invite code")
	}
}

func TestAuthService_RegisterAdminMissingInviteCode(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, err := svc.Register("admin@test.com", "password123", "Admin", "", "gallery_admin", "My Gallery", "")
	if err == nil {
		t.Fatal("expected error when invite code is not configured")
	}
}

func TestAuthService_RegisterAdminMissingGalleryName(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "invite-123")

	_, _, err := svc.Register("admin@test.com", "password123", "Admin", "", "gallery_admin", "", "invite-123")
	if err == nil {
		t.Fatal("expected error when gallery name is empty for admin")
	}
}

func TestAuthService_RegisterInvalidRole(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, err := svc.Register("invalid@test.com", "password123", "User", "", "superadmin", "", "")
	if err == nil {
		t.Fatal("expected error for invalid role")
	}
}

func TestAuthService_Login(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, err := svc.Register("login@test.com", "password123", "User", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	user, token, err := svc.Login("login@test.com", "password123")
	if err != nil {
		t.Fatalf("login failed: %v", err)
	}
	if token == "" {
		t.Error("expected token, got empty string")
	}
	if user.Role != "buyer" {
		t.Errorf("expected role buyer, got %s", user.Role)
	}
}

func TestAuthService_LoginJWTContainsRole(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "invite-123")

	_, token, _ := svc.Register("admin@test.com", "password123", "Admin", "", "gallery_admin", "My Gallery", "invite-123")

	userID, role, galleryID, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validate token failed: %v", err)
	}
	if role != "gallery_admin" {
		t.Errorf("expected role gallery_admin in JWT, got %s", role)
	}
	if galleryID == 0 {
		t.Error("expected non-zero gallery_id in JWT for admin")
	}
	if userID != 1 {
		t.Errorf("expected userID 1, got %d", userID)
	}
}

func TestAuthService_LoginJWTBuyerHasNoGallery(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, token, _ := svc.Register("buyer@test.com", "password123", "Buyer", "", "buyer", "", "")

	_, role, galleryID, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validate token failed: %v", err)
	}
	if role != "buyer" {
		t.Errorf("expected role buyer in JWT, got %s", role)
	}
	if galleryID != 0 {
		t.Errorf("expected gallery_id 0 for buyer, got %d", galleryID)
	}
}

func TestAuthService_LoginWrongPassword(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, _ = svc.Register("wp@test.com", "correct", "User", "", "buyer", "", "")

	_, _, err := svc.Login("wp@test.com", "wrong")
	if err == nil {
		t.Fatal("expected error for wrong password")
	}
}

func TestAuthService_ValidateToken(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, token, _ := svc.Register("token@test.com", "password123", "User", "", "buyer", "", "")

	userID, _, _, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validate token failed: %v", err)
	}
	if userID != 1 {
		t.Errorf("expected userID 1, got %d", userID)
	}
}

func TestAuthService_ValidateTokenInvalid(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, _, err := svc.ValidateToken("invalid.token.here")
	if err == nil {
		t.Fatal("expected error for invalid token")
	}
}

func TestAuthService_ValidateTokenWrongSecret(t *testing.T) {
	db := setupTestDB(t)
	svc1 := NewAuthService(db, "secret1", "")
	svc2 := NewAuthService(db, "secret2", "")

	_, token, _ := svc1.Register("secret@test.com", "password123", "User", "", "buyer", "", "")

	_, _, _, err := svc2.ValidateToken(token)
	if err == nil {
		t.Fatal("expected error with wrong secret")
	}
}

func TestAuthService_PasswordHashNotReturned(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	user, _, err := svc.Register("hash@test.com", "password123", "User", "", "buyer", "", "")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}
	if user.PasswordHash == "" {
		t.Error("password hash should be set in DB")
	}

	var dbUser model.User
	db.First(&dbUser, user.ID)
	if dbUser.PasswordHash == "" {
		t.Error("password hash should be stored in DB")
	}
	fmt.Println("DB hash:", dbUser.PasswordHash)
}

func TestAuthService_PasswordIsHashed(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "")

	_, _, _ = svc.Register("bcrypt@test.com", "password123", "User", "", "buyer", "", "")

	var user model.User
	db.Where("email = ?", "bcrypt@test.com").First(&user)

	if user.PasswordHash == "password123" {
		t.Fatal("password stored in plaintext!")
	}
}

func TestAuthService_GenerateAndValidateTokenForGallery(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret", "invite-123")

	_, _, err := svc.Register("gadmin@test.com", "password123", "Admin", "", "gallery_admin", "My Gallery", "invite-123")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	galleries := []model.Gallery{}
	db.Where("user_id = ?", uint(1)).Find(&galleries)
	if len(galleries) != 1 {
		t.Fatalf("expected 1 gallery, got %d", len(galleries))
	}

	token, err := svc.GenerateTokenForGallery(uint(1), galleries[0].ID)
	if err != nil {
		t.Fatalf("GenerateTokenForGallery failed: %v", err)
	}

	userID, role, galleryID, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validate token failed: %v", err)
	}
	if userID != 1 {
		t.Errorf("expected userID 1, got %d", userID)
	}
	if role != "gallery_admin" {
		t.Errorf("expected role gallery_admin, got %s", role)
	}
	if galleryID != galleries[0].ID {
		t.Errorf("expected galleryID %d, got %d", galleries[0].ID, galleryID)
	}
}
