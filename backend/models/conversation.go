package models

import "gorm.io/gorm"

type Conversation struct {
	gorm.Model
	HomeownerUserID    uint `json:"homeowner_user_id" gorm:"not null;uniqueIndex:idx_conversation_participants"`
	TradespersonUserID uint `json:"tradesperson_user_id" gorm:"not null;uniqueIndex:idx_conversation_participants"`

	HomeownerUser    User          `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:HomeownerUserID"`
	TradespersonUser User          `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:TradespersonUserID"`
	Messages         []ChatMessage `json:"-" gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:ConversationID"`
}
