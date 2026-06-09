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
}

func Load() *Config {
	_ = godotenv.Load()

	keyInput := os.Getenv("PRIVATE_KEY_PATH")

	keyBase64 := keyInput
	if data, err := os.ReadFile(keyInput); err == nil {
		keyBase64 = base64.StdEncoding.EncodeToString(data)
	}

	return &Config{
		WalletAddressURL: os.Getenv("WALLET_ADDRESS_URL"),
		PrivateKeyBase64: keyBase64,
		KeyID:            os.Getenv("KEY_ID"),
	}
}
