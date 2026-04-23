package models

<<<<<<< HEAD
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
=======
import "time"

type Booking struct {
	ID uint `gorm:"primarykey"`

	HomeownerID uint `json:"homeowner_id" gorm:"not null;index"`
	Homeowner   User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:HomeownerID"`

	TradespersonID uint `json:"tradesperson_id" gorm:"not null;index"`
	Tradesperson   User `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:TradespersonID"`

	TradeCategory      string  `json:"trade_category" gorm:"not null"`
	Specialization     string  `json:"specialization"`
	ProblemDescription string  `json:"problem_description" gorm:"not null"`
	Address            string  `json:"address" gorm:"not null"`
	PreferredDate      string  `json:"preferred_date" gorm:"not null"`
	PreferredTime      string  `json:"preferred_time" gorm:"not null"`
	OfferedBudget      float64 `json:"offered_budget" gorm:"not null"`

	Status      string     `json:"status" gorm:"not null;default:Pending"`
	CancelledAt *time.Time `json:"cancelled_at"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type BookingReview struct {
	ID uint `gorm:"primarykey"`

	BookingID uint    `json:"booking_id" gorm:"not null;uniqueIndex"`
	Booking   Booking `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:BookingID"`

	HomeownerID    uint `json:"homeowner_id" gorm:"not null;index"`
	TradespersonID uint `json:"tradesperson_id" gorm:"not null;index"`

	Rating  float64 `json:"rating" gorm:"not null"`
	Comment string  `json:"comment"`
	Tags    string  `json:"tags" gorm:"type:text"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type BookingIssue struct {
	ID uint `gorm:"primarykey"`

	BookingID uint    `json:"booking_id" gorm:"not null;index"`
	Booking   Booking `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:BookingID"`

	HomeownerID uint `json:"homeowner_id" gorm:"not null;index"`

	Category string `json:"category" gorm:"not null"`
	Details  string `json:"details" gorm:"not null"`
	Status   string `json:"status" gorm:"not null;default:Under Review"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
