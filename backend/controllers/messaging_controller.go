package controllers

import (
	"encoding/json"
	"errors"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/models"
	"fixit-backend/services"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

type messagingUser struct {
	ID   uint
	Role string
}

func ConversationsRoot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok := requireMessagingUser(w, r)
	if !ok {
		return
	}

	backfillConversationsForUser(user)

	var conversations []models.Conversation
	query := config.DB.Model(&models.Conversation{})
	if user.Role == "homeowner" {
		query = query.Where("homeowner_id = ?", user.ID).
			Where("homeowner_deleted_at IS NULL")
	} else {
		query = query.Where("tradesperson_id = ?", user.ID).
			Where("tradesperson_deleted_at IS NULL")
	}

	if err := query.Order("COALESCE(last_message_at, created_at) DESC").Find(&conversations).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load conversations")
		return
	}

	if len(conversations) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"conversations": []any{}})
		return
	}

	counterpartyIDs := make([]uint, 0, len(conversations))
	bookingIDs := make([]uint, 0, len(conversations))
	for _, c := range conversations {
		if user.Role == "homeowner" {
			counterpartyIDs = append(counterpartyIDs, c.TradespersonID)
		} else {
			counterpartyIDs = append(counterpartyIDs, c.HomeownerID)
		}
		if c.BookingID != nil && *c.BookingID != 0 {
			bookingIDs = append(bookingIDs, *c.BookingID)
		}
	}

	homeownersByID := getHomeownerProfilesByUserID(counterpartyIDs)
	tradespeopleByID := getTradespersonProfilesByUserID(counterpartyIDs)
	photosByUserID := getProfilePhotosByUserID(counterpartyIDs)
	bookingsByID := getBookingsByID(bookingIDs)
	unreadCounts := conversationUnreadCounts(conversations, user)
	now := time.Now().UTC()

	response := make([]map[string]any, 0, len(conversations))
	for _, c := range conversations {
		row := map[string]any{
			"id":          c.ID,
			"unreadCount": unreadCounts[c.ID],
			"time":        relativeTimeLabel(conversationTime(c)),
			"lastMessage": strings.TrimSpace(c.LastMessage),
			"isOnline":    false,
			"isArchived":  conversationArchivedForUser(c, user.Role),
			"isMuted":     conversationMutedForUser(c, user.Role, now),
		}

		if strings.TrimSpace(row["lastMessage"].(string)) == "" {
			row["lastMessage"] = "Start your conversation"
		}

		if user.Role == "homeowner" {
			profile := tradespeopleByID[c.TradespersonID]
			name := strings.TrimSpace(profile.FirstName + " " + profile.LastName)
			if name == "" {
				name = "Tradesperson"
			}

			trade := strings.TrimSpace(profile.TradeCategory)
			if trade == "" {
				trade = "General Services"
			}

			row["name"] = name
			row["avatar"] = initialsFromName(profile.FirstName, profile.LastName, "TP")
			row["trade"] = trade
			row["service"] = trade
			row["isOnline"] = profile.IsOnDuty
			row["other_user_id"] = c.TradespersonID
			row["profile_image_url"] = buildPublicUploadURL(r, photosByUserID[c.TradespersonID].FilePath)
		} else {
			profile := homeownersByID[c.HomeownerID]
			name := strings.TrimSpace(profile.FirstName + " " + profile.LastName)
			if name == "" {
				name = "Homeowner"
			}

			service := "Homeowner Request"
			if booking := bookingForConversation(c, bookingsByID); booking != nil {
				if strings.TrimSpace(booking.Specialization) != "" {
					service = strings.TrimSpace(booking.Specialization)
				} else if strings.TrimSpace(booking.TradeCategory) != "" {
					service = strings.TrimSpace(booking.TradeCategory)
				}
			}

			row["name"] = name
			row["avatar"] = initialsFromName(profile.FirstName, profile.LastName, "HM")
			row["service"] = service
			row["trade"] = service
			row["isOnline"] = true
			row["other_user_id"] = c.HomeownerID
			row["profile_image_url"] = buildPublicUploadURL(r, photosByUserID[c.HomeownerID].FilePath)
		}

		response = append(response, row)
	}

	writeJSON(w, http.StatusOK, map[string]any{"conversations": response})
}

func ConversationByIDRouter(w http.ResponseWriter, r *http.Request) {
	user, ok := requireMessagingUser(w, r)
	if !ok {
		return
	}

	conversationID, action, ok := parseConversationPath(r.URL.Path)
	if !ok {
		writeError(w, http.StatusNotFound, "endpoint not found")
		return
	}

	conversation, ok := getAuthorizedConversation(w, conversationID, user)
	if !ok {
		return
	}

	switch action {
	case "":
		switch r.Method {
		case http.MethodDelete:
			deleteConversationForUser(w, conversation, user)
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
	case "messages":
		switch r.Method {
		case http.MethodGet:
			getConversationMessages(w, r, conversation, user)
		case http.MethodPost:
			postConversationMessage(w, r, conversation, user)
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
	case "attachments":
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		postConversationAttachment(w, r, conversation, user)
	case "archive":
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		archiveConversationForUser(w, r, conversation, user)
	case "mute":
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		muteConversationForUser(w, r, conversation, user)
	case "read":
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		markConversationReadNow(w, conversation, user)
	default:
		writeError(w, http.StatusNotFound, "endpoint not found")
	}
}

func requireMessagingUser(w http.ResponseWriter, r *http.Request) (messagingUser, bool) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return messagingUser{}, false
	}

	userIDFloat, ok := claims["user_id"].(float64)
	if !ok {
		writeError(w, http.StatusUnauthorized, "invalid token claims")
		return messagingUser{}, false
	}

	role, _ := claims["role"].(string)
	if role != "homeowner" && role != "tradesperson" {
		writeError(w, http.StatusForbidden, "messaging is available to homeowners and tradespeople")
		return messagingUser{}, false
	}

	return messagingUser{ID: uint(userIDFloat), Role: role}, true
}

func parseConversationPath(path string) (uint, string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) < 3 || len(parts) > 4 || parts[0] != "api" || parts[1] != "conversations" {
		return 0, "", false
	}

	id, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil {
		return 0, "", false
	}

	action := ""
	if len(parts) == 4 {
		action = parts[3]
	}

	return uint(id), action, true
}

func getAuthorizedConversation(w http.ResponseWriter, conversationID uint, user messagingUser) (models.Conversation, bool) {
	var conversation models.Conversation
	query := config.DB.Where("id = ?", conversationID)
	if user.Role == "homeowner" {
		query = query.Where("homeowner_id = ?", user.ID).
			Where("homeowner_deleted_at IS NULL")
	} else {
		query = query.Where("tradesperson_id = ?", user.ID).
			Where("tradesperson_deleted_at IS NULL")
	}

	if err := query.First(&conversation).Error; err != nil {
		writeError(w, http.StatusNotFound, "conversation not found")
		return models.Conversation{}, false
	}

	return conversation, true
}

func getConversationMessages(
	w http.ResponseWriter,
	r *http.Request,
	conversation models.Conversation,
	user messagingUser,
) {
	var messages []models.ConversationMessage
	if err := config.DB.Where("conversation_id = ?", conversation.ID).Order("created_at ASC").Find(&messages).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load messages")
		return
	}

	if err := markConversationReadAt(conversation.ID, user, readTimestampFromMessages(messages)); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation read state")
		return
	}

	response := make([]map[string]any, 0, len(messages))
	for _, msg := range messages {
		response = append(response, conversationMessageResponse(r, msg, user.ID))
	}

	writeJSON(w, http.StatusOK, map[string]any{"messages": response})
}

func postConversationMessage(
	w http.ResponseWriter,
	r *http.Request,
	conversation models.Conversation,
	user messagingUser,
) {
	var req struct {
		Text string `json:"text"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	text := strings.TrimSpace(req.Text)
	if text == "" {
		writeError(w, http.StatusBadRequest, "message text is required")
		return
	}

	message := models.ConversationMessage{
		ConversationID: conversation.ID,
		SenderID:       user.ID,
		SenderRole:     user.Role,
		MessageType:    "text",
		Text:           text,
	}

	if err := config.DB.Create(&message).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to send message")
		return
	}

	if err := restoreConversationVisibilityAfterMessage(conversation.ID); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation")
		return
	}

	if err := updateConversationLastMessage(conversation.ID, text, message.CreatedAt); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation")
		return
	}

	if err := markConversationReadAt(conversation.ID, user, message.CreatedAt); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation read state")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message":      "message sent",
		"chat_message": conversationMessageResponse(r, message, user.ID),
	})
}

func postConversationAttachment(
	w http.ResponseWriter,
	r *http.Request,
	conversation models.Conversation,
	user messagingUser,
) {
	if err := r.ParseMultipartForm(25 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form data")
		return
	}

	file, header, err := r.FormFile("attachment")
	if err != nil {
		writeError(w, http.StatusBadRequest, "attachment is required")
		return
	}
	defer file.Close()

	_, storedPath, err := services.SaveUploadedFile(file, header, "chat_attachments")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to store attachment")
		return
	}

	attachmentName := strings.TrimSpace(header.Filename)
	if attachmentName == "" {
		attachmentName = "Attachment"
	}

	messageType := attachmentMessageType(attachmentName)
	message := models.ConversationMessage{
		ConversationID: conversation.ID,
		SenderID:       user.ID,
		SenderRole:     user.Role,
		MessageType:    messageType,
		Text:           attachmentName,
		AttachmentPath: storedPath,
		AttachmentName: attachmentName,
		AttachmentMime: strings.TrimSpace(header.Header.Get("Content-Type")),
	}

	if err := config.DB.Create(&message).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to send attachment")
		return
	}

	if err := restoreConversationVisibilityAfterMessage(conversation.ID); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation")
		return
	}

	lastMessage := "Sent an attachment"
	if messageType == "image" {
		lastMessage = "Sent a photo"
	}
	if err := updateConversationLastMessage(conversation.ID, lastMessage, message.CreatedAt); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation")
		return
	}

	if err := markConversationReadAt(conversation.ID, user, message.CreatedAt); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation read state")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message":      "attachment sent",
		"chat_message": conversationMessageResponse(r, message, user.ID),
	})
}

func conversationMessageResponse(r *http.Request, message models.ConversationMessage, currentUserID uint) map[string]any {
	sender := "other"
	if message.SenderID == currentUserID {
		sender = "me"
	}

	attachmentURL := ""
	if strings.TrimSpace(message.AttachmentPath) != "" {
		attachmentURL = buildPublicUploadURL(r, message.AttachmentPath)
	}

	return map[string]any{
		"id":             message.ID,
		"sender":         sender,
		"text":           message.Text,
		"time":           message.CreatedAt.Format("3:04 PM"),
		"sentAtIso":      message.CreatedAt.UTC().Format(time.RFC3339),
		"isAttachment":   message.MessageType == "image" || message.MessageType == "file",
		"attachmentType": message.MessageType,
		"attachmentName": message.AttachmentName,
		"attachmentPath": attachmentURL,
	}
}

func attachmentMessageType(filename string) string {
	ext := strings.ToLower(filepath.Ext(strings.TrimSpace(filename)))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".heic":
		return "image"
	default:
		return "file"
	}
}

func updateConversationLastMessage(conversationID uint, lastMessage string, at time.Time) error {
	trimmed := strings.TrimSpace(lastMessage)
	return config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversationID).
		Updates(map[string]any{
			"last_message":    trimmed,
			"last_message_at": at,
		}).Error
}

func deleteConversationForUser(w http.ResponseWriter, conversation models.Conversation, user messagingUser) {
	now := time.Now().UTC()
	updates := map[string]any{}
	if user.Role == "homeowner" {
		updates["homeowner_deleted_at"] = now
	} else {
		updates["tradesperson_deleted_at"] = now
	}

	if err := config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversation.ID).
		Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete conversation")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":               "conversation deleted",
		"deletedConversationId": conversation.ID,
	})
}

func archiveConversationForUser(
	w http.ResponseWriter,
	r *http.Request,
	conversation models.Conversation,
	user messagingUser,
) {
	var req struct {
		Archived *bool `json:"archived"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	archived := true
	if req.Archived != nil {
		archived = *req.Archived
	}

	updates := map[string]any{}
	if user.Role == "homeowner" {
		if archived {
			now := time.Now().UTC()
			updates["homeowner_archived_at"] = now
		} else {
			updates["homeowner_archived_at"] = nil
		}
	} else {
		if archived {
			now := time.Now().UTC()
			updates["tradesperson_archived_at"] = now
		} else {
			updates["tradesperson_archived_at"] = nil
		}
	}

	if err := config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversation.ID).
		Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update archive state")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":  "archive state updated",
		"archived": archived,
	})
}

func muteConversationForUser(
	w http.ResponseWriter,
	r *http.Request,
	conversation models.Conversation,
	user messagingUser,
) {
	var req struct {
		Muted         *bool `json:"muted"`
		DurationHours *int  `json:"durationHours"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	muted := true
	if req.Muted != nil {
		muted = *req.Muted
	}

	var mutedUntil *time.Time
	if muted {
		hours := 24 * 30
		if req.DurationHours != nil && *req.DurationHours > 0 {
			hours = *req.DurationHours
		}
		until := time.Now().UTC().Add(time.Duration(hours) * time.Hour)
		mutedUntil = &until
	}

	updates := map[string]any{}
	if user.Role == "homeowner" {
		updates["homeowner_muted_until"] = mutedUntil
	} else {
		updates["tradesperson_muted_until"] = mutedUntil
	}

	if err := config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversation.ID).
		Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update mute state")
		return
	}

	mutedUntilISO := ""
	if mutedUntil != nil {
		mutedUntilISO = mutedUntil.UTC().Format(time.RFC3339)
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":    "mute state updated",
		"muted":      muted,
		"mutedUntil": mutedUntilISO,
		"durationHours": func() int {
			if req.DurationHours != nil && *req.DurationHours > 0 {
				return *req.DurationHours
			}
			if muted {
				return 24 * 30
			}
			return 0
		}(),
	})
}

func markConversationReadNow(w http.ResponseWriter, conversation models.Conversation, user messagingUser) {
	readAt := time.Now().UTC()
	if err := markConversationReadAt(conversation.ID, user, readAt); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation read state")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "conversation marked as read",
		"readAt":  readAt.Format(time.RFC3339),
	})
}

func markConversationReadAt(conversationID uint, user messagingUser, readAt time.Time) error {
	updates := map[string]any{}
	if user.Role == "homeowner" {
		updates["homeowner_last_read_at"] = readAt.UTC()
	} else {
		updates["tradesperson_last_read_at"] = readAt.UTC()
	}

	return config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversationID).
		Updates(updates).Error
}

func restoreConversationVisibilityAfterMessage(conversationID uint) error {
	return config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversationID).
		Updates(map[string]any{
			"homeowner_deleted_at":     nil,
			"tradesperson_deleted_at":  nil,
			"homeowner_archived_at":    nil,
			"tradesperson_archived_at": nil,
		}).Error
}

func conversationUnreadCounts(conversations []models.Conversation, user messagingUser) map[uint]int {
	counts := make(map[uint]int, len(conversations))
	for _, c := range conversations {
		query := config.DB.Model(&models.ConversationMessage{}).
			Where("conversation_id = ?", c.ID).
			Where("sender_id <> ?", user.ID)

		if lastRead := conversationLastReadAtForUser(c, user.Role); lastRead != nil && !lastRead.IsZero() {
			query = query.Where("created_at > ?", *lastRead)
		}

		var unread int64
		if err := query.Count(&unread).Error; err != nil {
			counts[c.ID] = 0
			continue
		}
		counts[c.ID] = int(unread)
	}

	return counts
}

func conversationLastReadAtForUser(c models.Conversation, role string) *time.Time {
	if role == "homeowner" {
		return c.HomeownerLastReadAt
	}
	return c.TradespersonLastReadAt
}

func conversationArchivedForUser(c models.Conversation, role string) bool {
	if role == "homeowner" {
		return c.HomeownerArchivedAt != nil && !c.HomeownerArchivedAt.IsZero()
	}
	return c.TradespersonArchivedAt != nil && !c.TradespersonArchivedAt.IsZero()
}

func conversationMutedForUser(c models.Conversation, role string, now time.Time) bool {
	var mutedUntil *time.Time
	if role == "homeowner" {
		mutedUntil = c.HomeownerMutedUntil
	} else {
		mutedUntil = c.TradespersonMutedUntil
	}

	if mutedUntil == nil || mutedUntil.IsZero() {
		return false
	}
	return mutedUntil.After(now)
}

func readTimestampFromMessages(messages []models.ConversationMessage) time.Time {
	if len(messages) == 0 {
		return time.Now().UTC()
	}

	last := messages[len(messages)-1].CreatedAt
	if last.IsZero() {
		return time.Now().UTC()
	}

	return last.UTC()
}

func backfillConversationsForUser(user messagingUser) {
	var bookings []models.Booking
	query := config.DB.Model(&models.Booking{})
	if user.Role == "homeowner" {
		query = query.Where("homeowner_id = ?", user.ID)
	} else {
		query = query.Where("tradesperson_id = ?", user.ID)
	}

	if err := query.Find(&bookings).Error; err != nil {
		return
	}

	for _, booking := range bookings {
		bookingID := booking.ID
		_, _ = getOrCreateConversation(booking.HomeownerID, booking.TradespersonID, &bookingID)
	}
}

func getOrCreateConversation(homeownerID uint, tradespersonID uint, bookingID *uint) (models.Conversation, error) {
	var conversation models.Conversation
	err := config.DB.Where("homeowner_id = ? AND tradesperson_id = ?", homeownerID, tradespersonID).First(&conversation).Error
	if err == nil {
		if bookingID != nil && *bookingID != 0 && (conversation.BookingID == nil || *conversation.BookingID == 0) {
			if updateErr := config.DB.Model(&conversation).Update("booking_id", *bookingID).Error; updateErr == nil {
				conversation.BookingID = bookingID
			}
		}
		return conversation, nil
	}

	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return models.Conversation{}, err
	}

	conversation = models.Conversation{
		HomeownerID:    homeownerID,
		TradespersonID: tradespersonID,
		BookingID:      bookingID,
	}
	if err := config.DB.Create(&conversation).Error; err != nil {
		return models.Conversation{}, err
	}

	return conversation, nil
}

func bookingForConversation(c models.Conversation, bookingByID map[uint]models.Booking) *models.Booking {
	if c.BookingID == nil || *c.BookingID == 0 {
		return nil
	}

	booking, ok := bookingByID[*c.BookingID]
	if !ok {
		return nil
	}

	return &booking
}

func conversationTime(c models.Conversation) time.Time {
	if c.LastMessageAt != nil && !c.LastMessageAt.IsZero() {
		return *c.LastMessageAt
	}
	return c.CreatedAt
}
