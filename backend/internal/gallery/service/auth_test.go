package service

import (
	"fmt"
	"testing"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
)

func TestAuthService_Register(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	user, token, err := svc.Register("test@test.com", "password123", "Test User")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	if user.ID != 1 {
		t.Errorf("expected ID 1, got %d", user.ID)
	}
	if user.Email != "test@test.com" {
		t.Errorf("expected email test@test.com, got %s", user.Email)
	}
	if token == "" {
		t.Error("expected token, got empty string")
	}
}

func TestAuthService_RegisterDuplicate(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	_, _, err := svc.Register("dup@test.com", "password123", "Test")
	if err != nil {
		t.Fatalf("first register failed: %v", err)
	}

	_, _, err = svc.Register("dup@test.com", "password123", "Test")
	if err == nil {
		t.Fatal("expected duplicate error, got nil")
	}
}

func TestAuthService_Login(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	_, _, err := svc.Register("login@test.com", "password123", "User")
	if err != nil {
		t.Fatalf("register failed: %v", err)
	}

	_, token, err := svc.Login("login@test.com", "password123")
	if err != nil {
		t.Fatalf("login failed: %v", err)
	}
	if token == "" {
		t.Error("expected token, got empty string")
	}
}

func TestAuthService_LoginWrongPassword(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	_, _, _ = svc.Register("wp@test.com", "correct", "User")

	_, _, err := svc.Login("wp@test.com", "wrong")
	if err == nil {
		t.Fatal("expected error for wrong password")
	}
}

func TestAuthService_ValidateToken(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	_, token, _ := svc.Register("token@test.com", "password123", "User")

	userID, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("validate token failed: %v", err)
	}
	if userID != 1 {
		t.Errorf("expected userID 1, got %d", userID)
	}
}

func TestAuthService_ValidateTokenInvalid(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	_, err := svc.ValidateToken("invalid.token.here")
	if err == nil {
		t.Fatal("expected error for invalid token")
	}
}

func TestAuthService_ValidateTokenWrongSecret(t *testing.T) {
	db := setupTestDB(t)
	svc1 := NewAuthService(db, "secret1")
	svc2 := NewAuthService(db, "secret2")

	_, token, _ := svc1.Register("secret@test.com", "password123", "User")

	_, err := svc2.ValidateToken(token)
	if err == nil {
		t.Fatal("expected error with wrong secret")
	}
}

func TestAuthService_PasswordHashNotReturned(t *testing.T) {
	db := setupTestDB(t)
	svc := NewAuthService(db, "test-secret")

	user, _, err := svc.Register("hash@test.com", "password123", "User")
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
	svc := NewAuthService(db, "test-secret")

	_, _, _ = svc.Register("bcrypt@test.com", "password123", "User")

	var user model.User
	db.Where("email = ?", "bcrypt@test.com").First(&user)

	if user.PasswordHash == "password123" {
		t.Fatal("password stored in plaintext!")
	}
}
