package service

import (
	"testing"

	"github.com/whoAngeel/openpayments/internal/gallery/model"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	db, err := gorm.Open(sqlite.Open("file::memory:?_foreign_keys=on"), &gorm.Config{})
	if err != nil {
		t.Fatalf("failed to open test db: %v", err)
	}

	if err := db.AutoMigrate(
		&model.User{},
		&model.Gallery{},
		&model.Artisan{},
		&model.Product{},
		&model.Commission{},
	); err != nil {
		t.Fatalf("failed to migrate: %v", err)
	}

	return db
}
