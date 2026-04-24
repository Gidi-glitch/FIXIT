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

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}
