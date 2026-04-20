package models

import "gorm.io/gorm"

type UserProfilePhoto struct {
	gorm.Model
	UserID       uint   `json:"user_id" gorm:"uniqueIndex;not null"`
	OriginalName string `json:"original_name" gorm:"not null"`
	StoredName   string `json:"stored_name" gorm:"not null"`
	FilePath     string `json:"file_path" gorm:"not null"`
	MimeType     string `json:"mime_type"`
	FileSize     int64  `json:"file_size"`

	User User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`
}
