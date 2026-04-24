package config

import (
	"fmt"
	"log"
	"os"

	"fixit-backend/models"

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
		&models.AdminProfile{},
		&models.HomeownerProfile{},
		&models.HomeownerAddress{},
		&models.TradespersonProfile{},
		&models.VerificationDocument{},
		&models.UserProfilePhoto{},
		&models.ActivityLog{},
	); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}

	if err := migrateBookingsTable(db); err != nil {
		log.Fatal("❌ Failed to migrate bookings table:", err)
	}

	if err := migrateConversationsTable(db); err != nil {
		log.Fatal("❌ Failed to migrate conversations table:", err)
	}

	if err := db.AutoMigrate(
		&models.BookingReview{},
		&models.BookingIssue{},
		&models.ConversationMessage{},
	); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}
}

func migrateBookingsTable(db *gorm.DB) error {
	if !db.Migrator().HasTable(&models.Booking{}) {
		return db.AutoMigrate(&models.Booking{})
	}

	renames := []struct {
		oldName string
		newName string
	}{
		{oldName: "homeowner_user_id", newName: "homeowner_id"},
		{oldName: "tradesperson_user_id", newName: "tradesperson_id"},
		{oldName: "trade", newName: "trade_category"},
		{oldName: "date_label", newName: "preferred_date"},
		{oldName: "time_label", newName: "preferred_time"},
	}

	for _, item := range renames {
		oldExists, err := bookingColumnExists(db, item.oldName)
		if err != nil {
			return err
		}
		newExists, err := bookingColumnExists(db, item.newName)
		if err != nil {
			return err
		}

		switch {
		case oldExists && !newExists:
			if err := db.Exec(
				fmt.Sprintf(`ALTER TABLE "bookings" RENAME COLUMN "%s" TO "%s"`, item.oldName, item.newName),
			).Error; err != nil {
				return err
			}
		case oldExists && newExists:
			if err := db.Exec(
				fmt.Sprintf(
					`UPDATE "bookings" SET "%s" = COALESCE("%s", "%s") WHERE "%s" IS NULL`,
					item.newName,
					item.newName,
					item.oldName,
					item.newName,
				),
			).Error; err != nil {
				return err
			}
		}
	}

	return db.AutoMigrate(&models.Booking{})
}

func bookingColumnExists(db *gorm.DB, columnName string) (bool, error) {
	var exists bool
	err := db.Raw(
		`SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_schema = CURRENT_SCHEMA()
			  AND table_name = 'bookings'
			  AND column_name = ?
		)`,
		columnName,
	).Scan(&exists).Error
	return exists, err
}

func migrateConversationsTable(db *gorm.DB) error {
	if !db.Migrator().HasTable(&models.Conversation{}) {
		return db.AutoMigrate(&models.Conversation{})
	}

	renames := []struct {
		oldName string
		newName string
	}{
		{oldName: "homeowner_user_id", newName: "homeowner_id"},
		{oldName: "tradesperson_user_id", newName: "tradesperson_id"},
	}

	for _, item := range renames {
		oldExists, err := conversationColumnExists(db, item.oldName)
		if err != nil {
			return err
		}
		newExists, err := conversationColumnExists(db, item.newName)
		if err != nil {
			return err
		}

		switch {
		case oldExists && !newExists:
			if err := db.Exec(
				fmt.Sprintf(`ALTER TABLE "conversations" RENAME COLUMN "%s" TO "%s"`, item.oldName, item.newName),
			).Error; err != nil {
				return err
			}
		case oldExists && newExists:
			if err := db.Exec(
				fmt.Sprintf(
					`UPDATE "conversations" SET "%s" = COALESCE("%s", "%s") WHERE "%s" IS NULL`,
					item.newName,
					item.newName,
					item.oldName,
					item.newName,
				),
			).Error; err != nil {
				return err
			}
		}
	}

	return db.AutoMigrate(&models.Conversation{})
}

func conversationColumnExists(db *gorm.DB, columnName string) (bool, error) {
	var exists bool
	err := db.Raw(
		`SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_schema = CURRENT_SCHEMA()
			  AND table_name = 'conversations'
			  AND column_name = ?
		)`,
		columnName,
	).Scan(&exists).Error
	return exists, err
}
