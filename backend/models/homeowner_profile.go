package models

import "gorm.io/gorm"

type HomeownerProfile struct {
	gorm.Model
	UserID    uint   `json:"user_id" gorm:"uniqueIndex;not null"`
	FirstName string `json:"first_name" gorm:"not null"`
	LastName  string `json:"last_name" gorm:"not null"`
	Phone     string `json:"phone" gorm:"not null"`
	Gender    string `json:"gender"`
	Bio       string `json:"bio"`
	Barangay  string `json:"barangay" gorm:"not null"`
<<<<<<< HEAD
	StatusID  string `json:"status_id" gorm:"not null;default:pending"`
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}
