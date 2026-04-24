package models

import "time"

type HomeownerAddress struct {
	ID uint `gorm:"primarykey"`

	UserID uint `json:"user_id" gorm:"not null;index"`
	User   User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID"`

	Label        string `json:"label" gorm:"not null"`
	Unit         string `json:"unit"`
	Street       string `json:"street" gorm:"not null"`
	Barangay     string `json:"barangay" gorm:"not null"`
	Municipality string `json:"municipality" gorm:"not null;default:Calauan"`
	Province     string `json:"province" gorm:"not null;default:Laguna"`
	IsPrimary    bool   `json:"is_primary" gorm:"not null;default:false"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
