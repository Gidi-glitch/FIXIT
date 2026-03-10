package models

import "gorm.io/gorm"

type Homeowner struct {
	gorm.Model
	FullName string `json:"full_name"`
	Email    string `json:"email" gorm:"unique"`
	Phone    string `json:"phone"`
	Barangay string `json:"barangay"`
	Password string `json:"password"`
}