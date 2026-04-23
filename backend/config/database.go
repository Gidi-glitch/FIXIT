package config

import (
	"fmt"
	"log"
	"os"
<<<<<<< HEAD
	"strings"

	"fixit-backend/models"

	"golang.org/x/crypto/bcrypt"
=======

	"fixit-backend/models"

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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
<<<<<<< HEAD
		&models.TradespersonProfile{},
		&models.VerificationDocument{},
		&models.UserProfilePhoto{},
		&models.Conversation{},
		&models.ChatMessage{},
		&models.Booking{},
	); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}

	seedAdminUser(db)
}

func seedAdminUser(db *gorm.DB) {
	email := strings.ToLower(strings.TrimSpace(os.Getenv("ADMIN_EMAIL")))
	password := strings.TrimSpace(os.Getenv("ADMIN_PASSWORD"))
	fullName := strings.TrimSpace(os.Getenv("ADMIN_FULL_NAME"))

	if email == "" || password == "" {
		return
	}

	var existing models.User
	err := db.Where("email = ?", email).First(&existing).Error
	if err == nil {
		if existing.Role != "admin" {
			log.Printf("⚠️ Existing user %s is not an admin; skipping admin bootstrap", email)
		}
		return
	}
	if err != nil && err != gorm.ErrRecordNotFound {
		log.Printf("⚠️ Failed to check admin bootstrap user: %v", err)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("⚠️ Failed to hash ADMIN_PASSWORD: %v", err)
		return
	}

	admin := models.User{
		Email:        email,
		FullName:     fullName,
		PasswordHash: string(hashedPassword),
		Role:         "admin",
		IsActive:     true,
	}

	if err := db.Create(&admin).Error; err != nil {
		log.Printf("⚠️ Failed to create bootstrap admin user: %v", err)
		return
	}

	log.Printf("✅ Bootstrapped admin user: %s", email)
=======
		&models.HomeownerAddress{},
		&models.TradespersonProfile{},
		&models.VerificationDocument{},
		&models.UserProfilePhoto{},
		&models.Booking{},
		&models.Conversation{},
		&models.ConversationMessage{},
		&models.BookingReview{},
		&models.BookingIssue{},
	); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
