package models

import "gorm.io/gorm"

type VerificationDocument struct {
	gorm.Model
	UserID        uint   `json:"user_id" gorm:"index;not null"`
	DocumentGroup string `json:"document_group" gorm:"not null"`
	DocumentType  string `json:"document_type" gorm:"not null"`
	OriginalName  string `json:"original_name" gorm:"not null"`
	StoredName    string `json:"stored_name" gorm:"not null"`
	FilePath      string `json:"file_path" gorm:"not null"`
	MimeType      string `json:"mime_type"`
	FileSize      int64  `json:"file_size" gorm:"not null"`
	Status        string `json:"status" gorm:"not null;default:pending"`

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}