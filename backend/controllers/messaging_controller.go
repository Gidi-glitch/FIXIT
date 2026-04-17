package controllers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
)

type ensureConversationRequest struct {
	CounterpartUserID uint `json:"counterpart_user_id"`
}

type sendConversationMessageRequest struct {
	Text string `json:"text"`
}

func ListMarketplaceTradespeople(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	search := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("search")))
	category := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("category")))
	onDutyOnly := strings.EqualFold(strings.TrimSpace(r.URL.Query().Get("on_duty")), "true")

	var profiles []models.TradespersonProfile
	if err := config.DB.Preload("User").Order("created_at desc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, profile := range profiles {
		if !profile.User.IsActive {
			continue
		}

		name := buildDisplayName(profile.User.FullName, profile.FirstName, profile.LastName, profile.User.Email)
		trade := strings.TrimSpace(profile.TradeCategory)
		barangay := strings.TrimSpace(profile.ServiceBarangay)

		if search != "" {
			searchHaystack := strings.ToLower(strings.Join([]string{
				name,
				trade,
				barangay,
				profile.User.Email,
			}, " "))
			if !strings.Contains(searchHaystack, search) {
				continue
			}
		}

		if category != "" && category != "all" && !strings.Contains(strings.ToLower(trade), category) {
			continue
		}

		isOnDuty := true
		if onDutyOnly && !isOnDuty {
			continue
		}

		rows = append(rows, map[string]any{
			"id":                  profile.ID,
			"user_id":             profile.UserID,
			"name":                name,
			"email":               profile.User.Email,
			"trade":               trade,
			"specialization":      trade,
			"barangay":            barangay,
			"is_on_duty":          isOnDuty,
			"years_experience":    profile.YearsExperience,
			"experience_label":    formatExperienceLabel(profile.YearsExperience),
			"bio":                 profile.Bio,
			"skills":              []string{trade},
			"rating":              0.0,
			"reviews":             0,
			"completed_jobs":      0,
			"response_time":       "—",
			"verification_status": profile.VerificationStatus,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"tradespeople": rows})
}

func ConversationsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		ListConversations(w, r)
	case http.MethodPost:
		EnsureConversation(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func ConversationHandler(w http.ResponseWriter, r *http.Request) {
	path := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/conversations/"), "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	if len(parts) == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	conversationID, err := strconv.ParseUint(parts[0], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid conversation id")
		return
	}

	if len(parts) == 1 {
		if r.Method == http.MethodDelete {
			DeleteConversation(w, r, uint(conversationID))
			return
		}
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	if len(parts) == 2 && parts[1] == "messages" {
		switch r.Method {
		case http.MethodGet:
			ListConversationMessages(w, r, uint(conversationID))
		case http.MethodPost:
			SendConversationMessage(w, r, uint(conversationID))
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func ListConversations(w http.ResponseWriter, r *http.Request) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	conversations, err := listConversationsForUser(user)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load conversations")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"conversations": conversations})
}

func EnsureConversation(w http.ResponseWriter, r *http.Request) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	var req ensureConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.CounterpartUserID == 0 {
		writeError(w, http.StatusBadRequest, "counterpart_user_id is required")
		return
	}

	conversation, err := ensureConversationForUsers(user, req.CounterpartUserID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "counterpart user not found")
			return
		}
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	summary, err := buildConversationSummary(*conversation, user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build conversation")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":      "conversation ready",
		"conversation": summary,
	})
}

func ListConversationMessages(w http.ResponseWriter, r *http.Request, conversationID uint) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	conversation, err := loadConversationForParticipant(conversationID, user.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "conversation not found")
			return
		}
		writeError(w, http.StatusForbidden, "you do not have access to this conversation")
		return
	}

	var messages []models.ChatMessage
	if err := config.DB.Where("conversation_id = ?", conversation.ID).
		Order("created_at asc").
		Find(&messages).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load messages")
		return
	}

	rows := make([]map[string]any, 0, len(messages))
	for _, message := range messages {
		rows = append(rows, map[string]any{
			"id":              message.ID,
			"conversation_id": message.ConversationID,
			"sender_user_id":  message.SenderUserID,
			"text":            message.Text,
			"created_at":      message.CreatedAt,
		})
	}

	summary, err := buildConversationSummary(*conversation, user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to build conversation")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"conversation": summary,
		"messages":     rows,
	})
}

func SendConversationMessage(w http.ResponseWriter, r *http.Request, conversationID uint) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	conversation, err := loadConversationForParticipant(conversationID, user.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "conversation not found")
			return
		}
		writeError(w, http.StatusForbidden, "you do not have access to this conversation")
		return
	}

	var req sendConversationMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	text := strings.TrimSpace(req.Text)
	if text == "" {
		writeError(w, http.StatusBadRequest, "text is required")
		return
	}

	message := models.ChatMessage{
		ConversationID: conversation.ID,
		SenderUserID:   user.ID,
		Text:           text,
	}
	if err := config.DB.Create(&message).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to send message")
		return
	}
	if err := config.DB.Model(&models.Conversation{}).
		Where("id = ?", conversation.ID).
		Update("updated_at", time.Now()).
		Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update conversation")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": map[string]any{
			"id":              message.ID,
			"conversation_id": message.ConversationID,
			"sender_user_id":  message.SenderUserID,
			"text":            message.Text,
			"created_at":      message.CreatedAt,
		},
	})
}

func DeleteConversation(w http.ResponseWriter, r *http.Request, conversationID uint) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	conversation, err := loadConversationForParticipant(conversationID, user.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "conversation not found")
			return
		}
		writeError(w, http.StatusForbidden, "you do not have access to this conversation")
		return
	}

	if err := config.DB.Delete(&models.Conversation{}, conversation.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete conversation")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "conversation deleted"})
}

func ensureConversationForUsers(currentUser models.User, counterpartUserID uint) (*models.Conversation, error) {
	var counterpart models.User
	if err := config.DB.First(&counterpart, counterpartUserID).Error; err != nil {
		return nil, err
	}

	var homeownerID uint
	var tradespersonID uint

	switch currentUser.Role {
	case "homeowner":
		if counterpart.Role != "tradesperson" {
			return nil, errors.New("homeowners can only message tradespeople")
		}
		homeownerID = currentUser.ID
		tradespersonID = counterpart.ID
	case "tradesperson":
		if counterpart.Role != "homeowner" {
			return nil, errors.New("tradespeople can only message homeowners")
		}
		homeownerID = counterpart.ID
		tradespersonID = currentUser.ID
	default:
		return nil, errors.New("unsupported user role for conversations")
	}

	var conversation models.Conversation
	err := config.DB.Where(
		"homeowner_user_id = ? AND tradesperson_user_id = ?",
		homeownerID,
		tradespersonID,
	).First(&conversation).Error
	if err == nil {
		return loadConversationByID(conversation.ID)
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	conversation = models.Conversation{
		HomeownerUserID:    homeownerID,
		TradespersonUserID: tradespersonID,
	}
	if err := config.DB.Create(&conversation).Error; err != nil {
		return nil, err
	}

	return loadConversationByID(conversation.ID)
}

func listConversationsForUser(user models.User) ([]map[string]any, error) {
	var conversations []models.Conversation
	query := config.DB.Preload("HomeownerUser").Preload("TradespersonUser").Order("updated_at desc")
	switch user.Role {
	case "homeowner":
		query = query.Where("homeowner_user_id = ?", user.ID)
	case "tradesperson":
		query = query.Where("tradesperson_user_id = ?", user.ID)
	default:
		return []map[string]any{}, nil
	}

	if err := query.Find(&conversations).Error; err != nil {
		return nil, err
	}

	rows := make([]map[string]any, 0, len(conversations))
	for _, conversation := range conversations {
		summary, err := buildConversationSummary(conversation, user.ID)
		if err != nil {
			return nil, err
		}
		rows = append(rows, summary)
	}

	return rows, nil
}

func loadConversationForParticipant(conversationID, userID uint) (*models.Conversation, error) {
	conversation, err := loadConversationByID(conversationID)
	if err != nil {
		return nil, err
	}
	if conversation.HomeownerUserID != userID && conversation.TradespersonUserID != userID {
		return nil, errors.New("not a conversation participant")
	}
	return conversation, nil
}

func loadConversationByID(conversationID uint) (*models.Conversation, error) {
	var conversation models.Conversation
	if err := config.DB.Preload("HomeownerUser").Preload("TradespersonUser").First(&conversation, conversationID).Error; err != nil {
		return nil, err
	}
	return &conversation, nil
}

func buildConversationSummary(conversation models.Conversation, currentUserID uint) (map[string]any, error) {
	homeownerFirst, homeownerLast, homeownerBarangay, _, _ := getUserProfileDetails(conversation.HomeownerUserID, "homeowner")
	tradespersonFirst, tradespersonLast, _, tradespersonBio, _ := getUserProfileDetails(conversation.TradespersonUserID, "tradesperson")

	var tradespersonProfile models.TradespersonProfile
	_ = config.DB.Where("user_id = ?", conversation.TradespersonUserID).First(&tradespersonProfile).Error

	var latestMessage models.ChatMessage
	err := config.DB.Where("conversation_id = ?", conversation.ID).
		Order("created_at desc").
		First(&latestMessage).Error
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	isHomeowner := conversation.HomeownerUserID == currentUserID
	counterpartUser := conversation.HomeownerUser
	counterpartName := buildDisplayName(conversation.HomeownerUser.FullName, homeownerFirst, homeownerLast, conversation.HomeownerUser.Email)
	subtitle := strings.TrimSpace(homeownerBarangay)
	if isHomeowner {
		counterpartUser = conversation.TradespersonUser
		counterpartName = buildDisplayName(conversation.TradespersonUser.FullName, tradespersonFirst, tradespersonLast, conversation.TradespersonUser.Email)
		subtitle = strings.TrimSpace(tradespersonProfile.TradeCategory)
		if subtitle == "" {
			subtitle = strings.TrimSpace(tradespersonBio)
		}
	}

	lastMessage := ""
	lastMessageAt := ""
	if latestMessage.ID > 0 {
		lastMessage = latestMessage.Text
		lastMessageAt = latestMessage.CreatedAt.Format(time.RFC3339)
	}

	return map[string]any{
		"id":                  conversation.ID,
		"counterpart_user_id": counterpartUser.ID,
		"name":                counterpartName,
		"avatar":              initialsFromText(counterpartName),
		"last_message":        lastMessage,
		"last_message_at":     lastMessageAt,
		"unread_count":        0,
		"is_online":           counterpartUser.IsActive,
		"trade":               subtitle,
		"service":             subtitle,
	}, nil
}

func initialsFromText(value string) string {
	parts := strings.Fields(strings.TrimSpace(value))
	if len(parts) == 0 {
		return "NA"
	}
	if len(parts) == 1 {
		runes := []rune(parts[0])
		if len(runes) == 1 {
			return strings.ToUpper(parts[0])
		}
		return strings.ToUpper(string(runes[:2]))
	}
	return strings.ToUpper(string([]rune(parts[0])[:1])) + strings.ToUpper(string([]rune(parts[len(parts)-1])[:1]))
}

func formatExperienceLabel(years int) string {
	if years <= 0 {
		return "New"
	}
	if years == 1 {
		return "1 year"
	}
	return strconv.Itoa(years) + " years"
}
