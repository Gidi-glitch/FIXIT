package config

import (
	"fmt"
	"log"
	"os"

	"fixit-backend/models"
	"fixit-backend/services"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_SSLMODE"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("❌ Failed to connect to database:", err)
	}

	fmt.Println("✅ Connected to PostgreSQL (GORM)")

	DB = db

	if err := db.AutoMigrate(
		&models.User{},
		&models.HomeownerProfile{},
		&models.TradespersonProfile{},
		&models.VerificationDocument{},
		&models.ActivityLog{},
	); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}

	if err := services.BackfillHomeownerStatusID(db); err != nil {
		log.Printf("⚠️ Failed to backfill homeowner status_id: %v", err)
	}
}
