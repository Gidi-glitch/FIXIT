package models

import "time"

type Notification struct {
	ID        uint `gorm:"primarykey"`
	UserID    uint `json:"user_id" gorm:"not null;index"`
	Title     string `json:"title" gorm:"not null"`
	Message   string `json:"message" gorm:"not null;type:text"`
	Type      string `json:"type" gorm:"not null;index"` // booking_expired, booking_accepted, booking_cancelled, etc.
	IsRead    bool `json:"is_read" gorm:"default:false;index"`
	CreatedAt time.Time `json:"created_at"`
}
