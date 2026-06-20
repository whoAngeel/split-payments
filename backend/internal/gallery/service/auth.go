package service

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthService struct {
	db         *gorm.DB
	secret     []byte
	inviteCode string
}

func NewAuthService(db *gorm.DB, secret string, inviteCode string) *AuthService {
	return &AuthService{db: db, secret: []byte(secret), inviteCode: inviteCode}
}

func (s *AuthService) Register(email, password, name, walletAddressURL, role, galleryName, requestInviteCode string) (*model.User, string, error) {
	if role != "buyer" && role != "gallery_admin" {
		return nil, "", fmt.Errorf("invalid role: %s", role)
	}

	if role == "gallery_admin" {
		if s.inviteCode == "" {
			return nil, "", fmt.Errorf("admin registration is not enabled")
		}
		if requestInviteCode != s.inviteCode {
			return nil, "", fmt.Errorf("invalid invite code")
		}
		if galleryName == "" {
			return nil, "", fmt.Errorf("gallery name is required for admin registration")
		}
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, "", fmt.Errorf("hashing password: %w", err)
	}

	user := model.User{
		Email:            email,
		PasswordHash:     string(hash),
		Name:             name,
		WalletAddressURL: walletAddressURL,
		Role:             role,
	}

	err = s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return fmt.Errorf("creating user: %w", err)
		}

		if role == "gallery_admin" {
			gallery := model.Gallery{UserID: user.ID, Name: galleryName}
			if err := tx.Create(&gallery).Error; err != nil {
				return fmt.Errorf("creating gallery: %w", err)
			}
		}

		return nil
	})
	if err != nil {
		return nil, "", err
	}

	var galleryID uint
	if role == "gallery_admin" {
		var gallery model.Gallery
		if err := s.db.Where("user_id = ?", user.ID).First(&gallery).Error; err != nil {
			return nil, "", fmt.Errorf("finding gallery: %w", err)
		}
		galleryID = gallery.ID
	}

	token, err := s.generateToken(user.ID, role, galleryID)
	if err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

func (s *AuthService) GetUser(id uint) (*model.User, error) {
	var user model.User
	if err := s.db.First(&user, id).Error; err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return &user, nil
}

func (s *AuthService) Login(email, password string) (*model.User, string, error) {
	var user model.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	var galleryID uint
	if user.Role == "gallery_admin" {
		var gallery model.Gallery
		if err := s.db.Where("user_id = ?", user.ID).First(&gallery).Error; err != nil {
			return nil, "", fmt.Errorf("gallery not found: %w", err)
		}
		galleryID = gallery.ID
	}

	token, err := s.generateToken(user.ID, user.Role, galleryID)
	if err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

func (s *AuthService) ValidateToken(tokenStr string) (uint, string, uint, error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return s.secret, nil
	})
	if err != nil {
		return 0, "", 0, fmt.Errorf("parsing token: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return 0, "", 0, fmt.Errorf("invalid token")
	}

	userID, ok := claims["sub"].(float64)
	if !ok {
		return 0, "", 0, fmt.Errorf("invalid token subject")
	}

	role, _ := claims["role"].(string)

	galleryID := uint(0)
	if gid, ok := claims["gallery_id"].(float64); ok {
		galleryID = uint(gid)
	}

	return uint(userID), role, galleryID, nil
}

func (s *AuthService) GenerateTokenForGallery(userID, galleryID uint) (string, error) {
	var user model.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return "", fmt.Errorf("user not found: %w", err)
	}
	return s.generateToken(userID, user.Role, galleryID)
}

func (s *AuthService) generateToken(userID uint, role string, galleryID uint) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(24 * time.Hour).Unix(),
		"iat": time.Now().Unix(),
		"role": role,
	}

	if galleryID != 0 {
		claims["gallery_id"] = galleryID
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}
