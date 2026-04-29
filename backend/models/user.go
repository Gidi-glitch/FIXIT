package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	FullName         string     `json:"full_name"`
	Email            string     `json:"email" gorm:"uniqueIndex;not null"`
	PasswordHash     string     `json:"-" gorm:"not null"`
	Role             string     `json:"role" gorm:"not null"`
	IsActive         bool       `json:"is_active" gorm:"default:true"`
	SuspendedUntil   *time.Time `json:"suspended_until,omitempty" gorm:"index"`
	SuspensionReason string     `json:"suspension_reason,omitempty" gorm:"type:text;default:''"`
}
