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
	db     *gorm.DB
	secret []byte
}

func NewAuthService(db *gorm.DB, secret string) *AuthService {
	return &AuthService{db: db, secret: []byte(secret)}
}

func (s *AuthService) Register(email, password, name string) (*model.User, string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, "", fmt.Errorf("hashing password: %w", err)
	}

	user := model.User{
		Email:        email,
		PasswordHash: string(hash),
		Name:         name,
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, "", fmt.Errorf("creating user: %w", err)
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

func (s *AuthService) Login(email, password string) (*model.User, string, error) {
	var user model.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, "", fmt.Errorf("invalid credentials")
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

func (s *AuthService) ValidateToken(tokenStr string) (uint, error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return s.secret, nil
	})
	if err != nil {
		return 0, fmt.Errorf("parsing token: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return 0, fmt.Errorf("invalid token")
	}

	userID, ok := claims["sub"].(float64)
	if !ok {
		return 0, fmt.Errorf("invalid token subject")
	}

	return uint(userID), nil
}

func (s *AuthService) generateToken(userID uint) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(24 * time.Hour).Unix(),
		"iat": time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}
