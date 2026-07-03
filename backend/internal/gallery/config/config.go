package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL    string
	JWTSecret      string
	SplitterURL    string
	SplitterAPIKey string
	InviteCode     string
	MinioEndpoint  string
	MinioAccessKey string
	MinioSecretKey string
	MinioBucket    string
}

func Load() *Config {
	_ = godotenv.Load()

	return &Config{
		DatabaseURL:    os.Getenv("DATABASE_URL"),
		JWTSecret:      os.Getenv("JWT_SECRET"),
		SplitterURL:    os.Getenv("SPLITTER_URL"),
		SplitterAPIKey: os.Getenv("SPLITTER_API_KEY"),
		InviteCode:     os.Getenv("INVITE_CODE"),
		MinioEndpoint:  os.Getenv("MINIO_ENDPOINT"),
		MinioAccessKey: os.Getenv("MINIO_ACCESS_KEY"),
		MinioSecretKey: os.Getenv("MINIO_SECRET_KEY"),
		MinioBucket:    os.Getenv("MINIO_BUCKET"),
	}
}
