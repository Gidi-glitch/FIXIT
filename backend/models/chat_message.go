package models

import "gorm.io/gorm"

type ChatMessage struct {
	gorm.Model
	ConversationID uint   `json:"conversation_id" gorm:"index;not null"`
	SenderUserID   uint   `json:"sender_user_id" gorm:"index;not null"`
	Text           string `json:"text" gorm:"type:text;not null"`

	Conversation Conversation `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:ConversationID"`
	Sender       User         `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:SenderUserID"`
}
