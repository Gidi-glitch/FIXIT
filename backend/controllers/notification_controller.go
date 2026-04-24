package controllers

import (
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/models"

	"github.com/golang-jwt/jwt/v5"
)

// GetMyNotifications returns all notifications for the current user
func GetMyNotifications(w http.ResponseWriter, r *http.Request) {
	userID, ok := getCurrentUserID(w, r)
	if !ok {
		return
	}

	var notifications []models.Notification
	if err := config.DB.Where("user_id = ?", userID).Order("created_at DESC").Find(&notifications).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch notifications")
		return
	}

	rows := make([]map[string]any, 0, len(notifications))
	for _, n := range notifications {
		rows = append(rows, map[string]any{
			"id":         n.ID,
			"title":      n.Title,
			"message":    n.Message,
			"type":       n.Type,
			"is_read":    n.IsRead,
			"created_at": n.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"notifications": rows})
}

// GetMyUnreadNotifications returns only unread notifications for the current user
func GetMyUnreadNotifications(w http.ResponseWriter, r *http.Request) {
	userID, ok := getCurrentUserID(w, r)
	if !ok {
		return
	}

	var notifications []models.Notification
	if err := config.DB.Where("user_id = ? AND is_read = ?", userID, false).Order("created_at DESC").Find(&notifications).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to fetch unread notifications")
		return
	}

	rows := make([]map[string]any, 0, len(notifications))
	for _, n := range notifications {
		rows = append(rows, map[string]any{
			"id":         n.ID,
			"title":      n.Title,
			"message":    n.Message,
			"type":       n.Type,
			"is_read":    n.IsRead,
			"created_at": n.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"notifications": rows})
}

// GetUnreadCount returns the count of unread notifications
func GetUnreadCount(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	userID, ok := getCurrentUserID(w, r)
	if !ok {
		return
	}

	var count int64
	if err := config.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", userID, false).Count(&count).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to count unread notifications")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"unread_count": count})
}

// MarkNotificationAsRead marks a specific notification as read
func MarkNotificationAsRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	userID, ok := getCurrentUserID(w, r)
	if !ok {
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 5 {
		writeError(w, http.StatusBadRequest, "invalid request path")
		return
	}

	notificationID, err := strconv.ParseUint(parts[4], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid notification id")
		return
	}

	var notification models.Notification
	if err := config.DB.Where("id = ? AND user_id = ?", notificationID, userID).First(&notification).Error; err != nil {
		writeError(w, http.StatusNotFound, "notification not found")
		return
	}

	if notification.IsRead {
		writeJSON(w, http.StatusOK, map[string]any{"message": "notification already read"})
		return
	}

	if err := config.DB.Model(&notification).Update("is_read", true).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to mark notification as read")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"message": "notification marked as read"})
}

// MarkAllNotificationsAsRead marks all notifications as read for the current user
func MarkAllNotificationsAsRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	userID, ok := getCurrentUserID(w, r)
	if !ok {
		return
	}

	if err := config.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", userID, false).Update("is_read", true).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to mark all notifications as read")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"message": "all notifications marked as read"})
}

// getCurrentUserID extracts the user ID from the JWT token in the request context
func getCurrentUserID(w http.ResponseWriter, r *http.Request) (uint, bool) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return 0, false
	}

	userIDFloat, ok := claims["user_id"].(float64)
	if !ok {
		writeError(w, http.StatusUnauthorized, "invalid token claims")
		return 0, false
	}

	return uint(userIDFloat), true
}
