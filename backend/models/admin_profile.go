package models

import "gorm.io/gorm"

type AdminProfile struct {
	gorm.Model
	UserID   uint   `json:"user_id" gorm:"uniqueIndex;not null"`
	FullName string `json:"full_name" gorm:"not null"`

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}
