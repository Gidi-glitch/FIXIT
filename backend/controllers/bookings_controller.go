package controllers

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
)

type createBookingRequest struct {
	TradespersonUserID uint    `json:"tradesperson_user_id"`
	Trade              string  `json:"trade"`
	Specialization     string  `json:"specialization"`
	ProblemDescription string  `json:"problem_description"`
	Address            string  `json:"address"`
	Barangay           string  `json:"barangay"`
	Date               string  `json:"date"`
	Time               string  `json:"time"`
	OfferedBudget      float64 `json:"offered_budget"`
	Urgency            string  `json:"urgency"`
}

type updateBookingStatusRequest struct {
	Status string `json:"status"`
}

func BookingsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		ListBookings(w, r)
	case http.MethodPost:
		CreateBooking(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func BookingHandler(w http.ResponseWriter, r *http.Request) {
	path := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/bookings/"), "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	if len(parts) == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	bookingID, err := strconv.ParseUint(parts[0], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid booking id")
		return
	}

	if len(parts) == 1 {
		if r.Method == http.MethodGet {
			GetBooking(w, r, uint(bookingID))
			return
		}

		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	if len(parts) == 2 && parts[1] == "status" {
		if r.Method != http.MethodPatch {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}

		UpdateBookingStatus(w, r, uint(bookingID))
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func ListBookings(w http.ResponseWriter, r *http.Request) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	statusFilter := normalizeBookingStatus(r.URL.Query().Get("status"))

	query := config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		Order("created_at desc")

	switch normalizeRole(user.Role) {
	case "homeowner":
		query = query.Where("homeowner_user_id = ?", user.ID)
	case "tradesperson":
		query = query.Where("tradesperson_user_id = ?", user.ID)
	case "admin":
		// admins can view all bookings
	default:
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}

	if statusFilter != "" {
		query = query.Where("LOWER(status) = ?", strings.ToLower(statusFilter))
	}

	var bookings []models.Booking
	if err := query.Find(&bookings).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load bookings")
		return
	}

	rows, err := serializeBookings(bookings)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to serialize bookings")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"bookings": rows,
	})
}

func GetBooking(w http.ResponseWriter, r *http.Request, bookingID uint) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	var booking models.Booking
	if err := config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		First(&booking, bookingID).
		Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "booking not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to load booking")
		return
	}

	if !canViewBooking(user, booking) {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}

	rows, err := serializeBookings([]models.Booking{booking})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to serialize booking")
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusInternalServerError, "failed to serialize booking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"booking": rows[0],
	})
}

func CreateBooking(w http.ResponseWriter, r *http.Request) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	if normalizeRole(user.Role) != "homeowner" {
		writeError(w, http.StatusForbidden, "only homeowners can create bookings")
		return
	}

	var req createBookingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	req.Trade = strings.TrimSpace(req.Trade)
	req.Specialization = strings.TrimSpace(req.Specialization)
	req.ProblemDescription = strings.TrimSpace(req.ProblemDescription)
	req.Address = strings.TrimSpace(req.Address)
	req.Barangay = strings.TrimSpace(req.Barangay)
	req.Date = strings.TrimSpace(req.Date)
	req.Time = strings.TrimSpace(req.Time)
	urgency := normalizeBookingUrgency(req.Urgency)
	if urgency == "" {
		urgency = inferUrgencyFromDateLabel(req.Date)
	}

	if req.TradespersonUserID == 0 || req.Trade == "" || req.Specialization == "" || req.ProblemDescription == "" || req.Address == "" || req.Date == "" || req.Time == "" {
		writeError(w, http.StatusBadRequest, "missing required booking fields")
		return
	}
	if req.OfferedBudget < 0 {
		writeError(w, http.StatusBadRequest, "offered_budget must be a positive number")
		return
	}

	var tradesperson models.User
	if err := config.DB.First(&tradesperson, req.TradespersonUserID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "tradesperson not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to validate tradesperson")
		return
	}
	if normalizeRole(tradesperson.Role) != "tradesperson" {
		writeError(w, http.StatusBadRequest, "target user is not a tradesperson")
		return
	}
	if !tradesperson.IsActive {
		writeError(w, http.StatusBadRequest, "selected tradesperson is not active")
		return
	}

	barangay := req.Barangay
	if barangay == "" {
		var homeownerProfile models.HomeownerProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&homeownerProfile).Error; err == nil {
			barangay = strings.TrimSpace(homeownerProfile.Barangay)
		}
	}

	booking := models.Booking{
		HomeownerUserID:    user.ID,
		TradespersonUserID: req.TradespersonUserID,
		Trade:              req.Trade,
		Specialization:     req.Specialization,
		ProblemDescription: req.ProblemDescription,
		Address:            req.Address,
		Barangay:           barangay,
		DateLabel:          req.Date,
		TimeLabel:          req.Time,
		OfferedBudget:      req.OfferedBudget,
		Urgency:            urgency,
		Status:             "Pending",
	}

	if err := config.DB.Create(&booking).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create booking")
		return
	}

	if err := config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		First(&booking, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load created booking")
		return
	}

	rows, err := serializeBookings([]models.Booking{booking})
	if err != nil || len(rows) == 0 {
		writeError(w, http.StatusInternalServerError, "failed to serialize booking")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": "booking created",
		"booking": rows[0],
	})
}

func UpdateBookingStatus(w http.ResponseWriter, r *http.Request, bookingID uint) {
	user, ok := getAuthenticatedUser(w, r)
	if !ok {
		return
	}

	var booking models.Booking
	if err := config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		First(&booking, bookingID).
		Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusNotFound, "booking not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to load booking")
		return
	}

	var req updateBookingStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	nextStatus := normalizeBookingStatus(req.Status)
	if nextStatus == "" {
		writeError(w, http.StatusBadRequest, "invalid status")
		return
	}

	if err := authorizeAndValidateStatusTransition(user, booking, nextStatus); err != nil {
		if err.Error() == "forbidden" {
			writeError(w, http.StatusForbidden, "forbidden")
			return
		}
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	updates := map[string]any{"status": nextStatus}
	now := time.Now()
	if nextStatus == "In Progress" && booking.StartedAt == nil {
		updates["started_at"] = now
	}
	if nextStatus == "Completed" {
		if booking.StartedAt == nil {
			updates["started_at"] = now
		}
		if booking.CompletedAt == nil {
			updates["completed_at"] = now
		}
	}

	if err := config.DB.Model(&booking).Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update booking")
		return
	}

	if err := config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		First(&booking, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to reload booking")
		return
	}

	rows, err := serializeBookings([]models.Booking{booking})
	if err != nil || len(rows) == 0 {
		writeError(w, http.StatusInternalServerError, "failed to serialize booking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "booking updated",
		"booking": rows[0],
	})
}

func serializeBookings(bookings []models.Booking) ([]map[string]any, error) {
	homeownerIDs := make([]uint, 0, len(bookings))
	tradespersonIDs := make([]uint, 0, len(bookings))
	for _, booking := range bookings {
		homeownerIDs = append(homeownerIDs, booking.HomeownerUserID)
		tradespersonIDs = append(tradespersonIDs, booking.TradespersonUserID)
	}

	homeownerProfiles, err := loadHomeownerProfileMap(homeownerIDs)
	if err != nil {
		return nil, err
	}
	tradespersonProfiles, err := loadTradespersonProfileMap(tradespersonIDs)
	if err != nil {
		return nil, err
	}

	rows := make([]map[string]any, 0, len(bookings))
	for _, booking := range bookings {
		homeownerProfile := homeownerProfiles[booking.HomeownerUserID]
		tradespersonProfile := tradespersonProfiles[booking.TradespersonUserID]

		homeownerName := buildDisplayName(
			booking.HomeownerUser.FullName,
			homeownerProfile.FirstName,
			homeownerProfile.LastName,
			booking.HomeownerUser.Email,
		)
		tradespersonName := buildDisplayName(
			booking.TradespersonUser.FullName,
			tradespersonProfile.FirstName,
			tradespersonProfile.LastName,
			booking.TradespersonUser.Email,
		)

		status := normalizeBookingStatus(booking.Status)
		if status == "" {
			status = "Pending"
		}
		urgency := normalizeBookingUrgency(booking.Urgency)
		if urgency == "" {
			urgency = inferUrgencyFromDateLabel(booking.DateLabel)
		}

		rows = append(rows, map[string]any{
			"id":                   booking.ID,
			"booking_code":         fmt.Sprintf("BK-%06d", booking.ID),
			"homeowner_user_id":    booking.HomeownerUserID,
			"homeowner_name":       homeownerName,
			"homeowner_avatar":     buildAvatarInitials(homeownerName),
			"tradesperson_user_id": booking.TradespersonUserID,
			"tradesperson_name":    tradespersonName,
			"tradesperson_avatar":  buildAvatarInitials(tradespersonName),
			"trade":                booking.Trade,
			"service":              booking.Specialization,
			"specialization":       booking.Specialization,
			"problem_description":  booking.ProblemDescription,
			"description":          booking.ProblemDescription,
			"address":              booking.Address,
			"barangay":             firstNonEmpty(strings.TrimSpace(booking.Barangay), strings.TrimSpace(homeownerProfile.Barangay)),
			"date":                 booking.DateLabel,
			"time":                 booking.TimeLabel,
			"offered_budget":       booking.OfferedBudget,
			"budget":               booking.OfferedBudget,
			"urgency":              urgency,
			"status":               status,
			"is_new":               time.Since(booking.CreatedAt) <= 24*time.Hour,
			"posted_at":            timeAgoLabel(booking.CreatedAt),
			"created_at":           booking.CreatedAt,
			"updated_at":           booking.UpdatedAt,
			"started_at":           booking.StartedAt,
			"completed_at":         booking.CompletedAt,
		})
	}

	return rows, nil
}

func loadHomeownerProfileMap(userIDs []uint) (map[uint]models.HomeownerProfile, error) {
	out := make(map[uint]models.HomeownerProfile)
	if len(userIDs) == 0 {
		return out, nil
	}

	var profiles []models.HomeownerProfile
	if err := config.DB.Where("user_id IN ?", uniqueUintSlice(userIDs)).Find(&profiles).Error; err != nil {
		return nil, err
	}

	for _, profile := range profiles {
		out[profile.UserID] = profile
	}
	return out, nil
}

func loadTradespersonProfileMap(userIDs []uint) (map[uint]models.TradespersonProfile, error) {
	out := make(map[uint]models.TradespersonProfile)
	if len(userIDs) == 0 {
		return out, nil
	}

	var profiles []models.TradespersonProfile
	if err := config.DB.Where("user_id IN ?", uniqueUintSlice(userIDs)).Find(&profiles).Error; err != nil {
		return nil, err
	}

	for _, profile := range profiles {
		out[profile.UserID] = profile
	}
	return out, nil
}

func uniqueUintSlice(ids []uint) []uint {
	seen := make(map[uint]struct{}, len(ids))
	out := make([]uint, 0, len(ids))
	for _, id := range ids {
		if id == 0 {
			continue
		}
		if _, exists := seen[id]; exists {
			continue
		}
		seen[id] = struct{}{}
		out = append(out, id)
	}
	return out
}

func normalizeBookingStatus(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "pending":
		return "Pending"
	case "accepted":
		return "Accepted"
	case "in progress", "in_progress", "in-progress":
		return "In Progress"
	case "completed":
		return "Completed"
	case "under review", "under_review", "under-review":
		return "Under Review"
	case "disputed":
		return "Disputed"
	case "cancelled", "canceled":
		return "Cancelled"
	default:
		return ""
	}
}

func normalizeBookingUrgency(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "high":
		return "High"
	case "medium":
		return "Medium"
	case "low":
		return "Low"
	default:
		return ""
	}
}

func inferUrgencyFromDateLabel(dateLabel string) string {
	switch strings.ToLower(strings.TrimSpace(dateLabel)) {
	case "today":
		return "High"
	case "tomorrow":
		return "Medium"
	default:
		return "Low"
	}
}

func normalizeRole(role string) string {
	switch strings.ToLower(strings.TrimSpace(role)) {
	case "tradesman", "tradesperson":
		return "tradesperson"
	default:
		return strings.ToLower(strings.TrimSpace(role))
	}
}

func canViewBooking(user models.User, booking models.Booking) bool {
	switch normalizeRole(user.Role) {
	case "admin":
		return true
	case "homeowner":
		return booking.HomeownerUserID == user.ID
	case "tradesperson":
		return booking.TradespersonUserID == user.ID
	default:
		return false
	}
}

func authorizeAndValidateStatusTransition(user models.User, booking models.Booking, nextStatus string) error {
	role := normalizeRole(user.Role)
	if !canViewBooking(user, booking) {
		return errors.New("forbidden")
	}

	currentStatus := normalizeBookingStatus(booking.Status)
	if currentStatus == "" {
		currentStatus = "Pending"
	}

	if currentStatus == nextStatus {
		return nil
	}

	switch role {
	case "homeowner":
		if nextStatus != "Cancelled" && nextStatus != "Under Review" && nextStatus != "Disputed" {
			return errors.New("homeowners can only set status to Cancelled, Under Review, or Disputed")
		}
	case "tradesperson":
		if nextStatus != "Accepted" && nextStatus != "In Progress" && nextStatus != "Completed" && nextStatus != "Cancelled" {
			return errors.New("tradespeople can only set status to Accepted, In Progress, Completed, or Cancelled")
		}
	case "admin":
		// admins can force-update any valid status
	default:
		return errors.New("forbidden")
	}

	if currentStatus == "Completed" && nextStatus != "Completed" && role != "admin" {
		return errors.New("completed bookings cannot be changed")
	}

	switch nextStatus {
	case "Accepted":
		if currentStatus != "Pending" {
			return errors.New("only pending bookings can be accepted")
		}
	case "In Progress":
		if currentStatus != "Accepted" {
			return errors.New("only accepted bookings can be started")
		}
	case "Completed":
		if currentStatus != "In Progress" && currentStatus != "Accepted" {
			return errors.New("only accepted or in-progress bookings can be completed")
		}
	case "Cancelled":
		if currentStatus == "Completed" {
			return errors.New("completed bookings cannot be cancelled")
		}
	}

	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}

func buildAvatarInitials(name string) string {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return "NA"
	}

	parts := strings.Fields(trimmed)
	if len(parts) == 1 {
		first := []rune(parts[0])
		if len(first) == 0 {
			return "NA"
		}
		return strings.ToUpper(string(first[0]))
	}

	first := []rune(parts[0])
	last := []rune(parts[len(parts)-1])
	if len(first) == 0 || len(last) == 0 {
		return "NA"
	}

	return strings.ToUpper(string(first[0]) + string(last[0]))
}

func timeAgoLabel(t time.Time) string {
	if t.IsZero() {
		return "just now"
	}

	delta := time.Since(t)
	switch {
	case delta < time.Minute:
		return "just now"
	case delta < time.Hour:
		return fmt.Sprintf("%d mins ago", int(delta.Minutes()))
	case delta < 24*time.Hour:
		return fmt.Sprintf("%d hours ago", int(delta.Hours()))
	case delta < 48*time.Hour:
		return "1 day ago"
	default:
		return fmt.Sprintf("%d days ago", int(delta.Hours()/24))
	}
}
