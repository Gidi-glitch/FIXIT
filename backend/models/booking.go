package models

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

	Status             string     `json:"status" gorm:"not null;default:Pending"`
	RespondedAt        *time.Time `json:"responded_at,omitempty" gorm:"index"`
	AcceptedAt         *time.Time `json:"accepted_at,omitempty" gorm:"index"`
	StartedAt          *time.Time `json:"started_at,omitempty" gorm:"index"`
	CancelledAt        *time.Time `json:"cancelled_at"`
	CompletedAt        *time.Time `json:"completed_at"`
	CancellationReason string     `json:"cancellation_reason,omitempty" gorm:"default:''"`
	ExpirationTime     *time.Time `json:"expiration_time,omitempty" gorm:"index"`

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

	Category              string     `json:"category" gorm:"not null"`
	Details               string     `json:"details" gorm:"not null"`
	Status                string     `json:"status" gorm:"not null;default:Under Review"`
	PreviousBookingStatus string     `json:"previous_booking_status,omitempty" gorm:"default:''"`
	ResolvedAt            *time.Time `json:"resolved_at,omitempty" gorm:"index"`
	ResolutionNote        string     `json:"resolution_note,omitempty" gorm:"type:text;default:''"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
