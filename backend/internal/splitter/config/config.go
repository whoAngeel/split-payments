package config

import (
	"encoding/base64"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	WalletAddressURL string
	PrivateKeyBase64 string
	KeyID            string
	APIKey           string
	PublicURL        string
}

func Load() *Config {
	_ = godotenv.Load()

	keyInput := os.Getenv("PRIVATE_KEY_PATH")

	keyBase64 := keyInput
	if data, err := os.ReadFile(keyInput); err == nil {
		keyBase64 = base64.StdEncoding.EncodeToString(data)
	}

	publicURL := os.Getenv("SPLITTER_PUBLIC_URL")
	if publicURL == "" {
		publicURL = "http://localhost:4001"
	}

	return &Config{
		WalletAddressURL: os.Getenv("WALLET_ADDRESS_URL"),
		PrivateKeyBase64: keyBase64,
		KeyID:            os.Getenv("KEY_ID"),
		APIKey:           os.Getenv("SPLITTER_API_KEY"),
		PublicURL:        publicURL,
	}
}
