package models

import (
	"time"

	"gorm.io/gorm"
)

type Booking struct {
	gorm.Model
	HomeownerUserID    uint       `json:"homeowner_user_id" gorm:"index;not null"`
	TradespersonUserID uint       `json:"tradesperson_user_id" gorm:"index;not null"`
	Trade              string     `json:"trade" gorm:"not null"`
	Specialization     string     `json:"specialization" gorm:"type:text;not null"`
	ProblemDescription string     `json:"problem_description" gorm:"type:text;not null"`
	Address            string     `json:"address" gorm:"type:text;not null"`
	Barangay           string     `json:"barangay"`
	DateLabel          string     `json:"date" gorm:"not null"`
	TimeLabel          string     `json:"time" gorm:"not null"`
	OfferedBudget      float64    `json:"offered_budget" gorm:"not null"`
	Urgency            string     `json:"urgency" gorm:"not null;default:Medium"`
	Status             string     `json:"status" gorm:"not null;default:Pending"`
	StartedAt          *time.Time `json:"started_at"`
	CompletedAt        *time.Time `json:"completed_at"`

	HomeownerUser    User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:HomeownerUserID"`
	TradespersonUser User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:TradespersonUserID"`
}
