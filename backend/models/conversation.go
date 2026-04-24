package models

import "time"

type Conversation struct {
	ID uint `gorm:"primarykey"`

	HomeownerID    uint  `json:"homeowner_id" gorm:"not null;index;uniqueIndex:idx_conversation_pair,priority:1"`
	TradespersonID uint  `json:"tradesperson_id" gorm:"not null;index;uniqueIndex:idx_conversation_pair,priority:2"`
	BookingID      *uint `json:"booking_id" gorm:"index"`

	LastMessage   string     `json:"last_message" gorm:"type:text"`
	LastMessageAt *time.Time `json:"last_message_at"`

	HomeownerLastReadAt    *time.Time `json:"homeowner_last_read_at" gorm:"index"`
	TradespersonLastReadAt *time.Time `json:"tradesperson_last_read_at" gorm:"index"`

	HomeownerArchivedAt    *time.Time `json:"homeowner_archived_at" gorm:"index"`
	TradespersonArchivedAt *time.Time `json:"tradesperson_archived_at" gorm:"index"`

	HomeownerMutedUntil    *time.Time `json:"homeowner_muted_until" gorm:"index"`
	TradespersonMutedUntil *time.Time `json:"tradesperson_muted_until" gorm:"index"`

	HomeownerDeletedAt    *time.Time `json:"homeowner_deleted_at" gorm:"index"`
	TradespersonDeletedAt *time.Time `json:"tradesperson_deleted_at" gorm:"index"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ConversationMessage struct {
	ID uint `gorm:"primarykey"`

	ConversationID uint   `json:"conversation_id" gorm:"not null;index"`
	SenderID       uint   `json:"sender_id" gorm:"not null;index"`
	SenderRole     string `json:"sender_role" gorm:"not null"`

	MessageType string `json:"message_type" gorm:"not null;default:text"`
	Text        string `json:"text" gorm:"type:text"`

	AttachmentPath string `json:"attachment_path"`
	AttachmentName string `json:"attachment_name"`
	AttachmentMime string `json:"attachment_mime"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
