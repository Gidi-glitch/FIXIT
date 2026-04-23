package models

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Email        string `json:"email" gorm:"uniqueIndex;not null"`
<<<<<<< HEAD
	FullName     string `json:"full_name"`
	PasswordHash string `json:"-" gorm:"not null"`
	Role         string `json:"role" gorm:"not null"`
	IsActive     bool   `json:"is_active" gorm:"default:true"`
}
=======
	PasswordHash string `json:"-" gorm:"not null"`
	Role         string `json:"role" gorm:"not null"`
	IsActive     bool   `json:"is_active" gorm:"default:true"`
}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
