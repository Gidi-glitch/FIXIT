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
<<<<<<< HEAD
=======
	ServiceAreas       string `json:"service_areas" gorm:"type:text"`
	Specializations    string `json:"specializations" gorm:"type:text"`
	ExperienceLevel    string `json:"experience_level"`
	RateRange          string `json:"rate_range"`
	IsOnDuty           bool   `json:"is_on_duty" gorm:"not null;default:true"`
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
	Gender             string `json:"gender"`
	Bio                string `json:"bio"`
	VerificationStatus string `json:"verification_status" gorm:"not null;default:pending"`

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}
