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
}

func Load() *Config {
	_ = godotenv.Load()

	return &Config{
		DatabaseURL:    os.Getenv("DATABASE_URL"),
		JWTSecret:      os.Getenv("JWT_SECRET"),
		SplitterURL:    os.Getenv("SPLITTER_URL"),
		SplitterAPIKey: os.Getenv("SPLITTER_API_KEY"),
	}
}
