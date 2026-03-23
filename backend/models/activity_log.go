package models

import "gorm.io/gorm"

// ActivityLog stores admin activity feed entries.
type ActivityLog struct {
	gorm.Model
	Title string `json:"title" gorm:"not null"`
	Sub   string `json:"sub" gorm:"not null"`
	Type  string `json:"type" gorm:"not null"`
}
