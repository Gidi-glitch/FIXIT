package models

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Email        string `json:"email" gorm:"uniqueIndex;not null"`
	FullName     string `json:"full_name"`
	PasswordHash string `json:"-" gorm:"not null"`
	Role         string `json:"role" gorm:"not null"`
	IsActive     bool   `json:"is_active" gorm:"default:true"`
}
