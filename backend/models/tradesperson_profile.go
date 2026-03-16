package models

import "gorm.io/gorm"

type TradespersonProfile struct {
	gorm.Model
	UserID             uint   `json:"user_id" gorm:"uniqueIndex;not null"`
	FirstName          string `json:"first_name" gorm:"not null"`
	LastName           string `json:"last_name" gorm:"not null"`
	Phone              string `json:"phone" gorm:"not null"`
	TradeCategory      string `json:"trade_category" gorm:"not null"`
	YearsExperience    int    `json:"years_experience" gorm:"not null"`
	ServiceBarangay    string `json:"service_barangay" gorm:"not null"`
	Bio                string `json:"bio"`
	VerificationStatus string `json:"verification_status" gorm:"not null;default:pending"`

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}