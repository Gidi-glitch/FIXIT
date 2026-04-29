package controllers

import (
	"encoding/json"
	"fmt"
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

type createBookingRequest struct {
	TradespersonID     uint    `json:"tradesperson_id"`
	TradeCategory      string  `json:"trade_category"`
	Specialization     string  `json:"specialization"`
	ProblemDescription string  `json:"problem_description"`
	Address            string  `json:"address"`
	Date               string  `json:"date"`
	Time               string  `json:"time"`
	OfferedBudget      float64 `json:"offered_budget"`
}

type updateBookingRequest struct {
	Specialization     *string  `json:"specialization"`
	ProblemDescription *string  `json:"problem_description"`
	Address            *string  `json:"address"`
	Date               *string  `json:"date"`
	Time               *string  `json:"time"`
	OfferedBudget      *float64 `json:"offered_budget"`
}

type reviewBookingRequest struct {
	Rating  float64  `json:"rating"`
	Comment string   `json:"comment"`
	Tags    []string `json:"tags"`
}

type reportBookingIssueRequest struct {
	Category string `json:"category"`
	Details  string `json:"details"`
}

type updateOnDutyRequest struct {
	IsOnDuty  *bool `json:"is_on_duty"`
	IsOnDuty2 *bool `json:"isOnDuty"`
}

func ListTradespeopleForHomeowner(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	if _, ok := requireHomeowner(w, r); !ok {
		return
	}

	search := strings.TrimSpace(strings.ToLower(r.URL.Query().Get("search")))
	category := strings.TrimSpace(r.URL.Query().Get("category"))
	onDutyRaw := strings.TrimSpace(r.URL.Query().Get("on_duty"))
	onDutyOnly, hasOnDutyFilter := parseBoolQuery(onDutyRaw)

	query := config.DB.Model(&models.TradespersonProfile{}).Where("verification_status = ?", "approved")
	if category != "" && strings.ToLower(category) != "all" {
		query = query.Where("LOWER(trade_category) = ?", strings.ToLower(category))
	}
	if hasOnDutyFilter {
		query = query.Where("is_on_duty = ?", onDutyOnly)
	}
	if search != "" {
		like := "%" + search + "%"
		query = query.Where(
			"LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(trade_category) LIKE ? OR LOWER(service_barangay) LIKE ?",
			like,
			like,
			like,
			like,
		)
	}

	var profiles []models.TradespersonProfile
	if err := query.Order("created_at DESC").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	if len(profiles) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"tradespeople": []map[string]any{}})
		return
	}

	userIDs := make([]uint, 0, len(profiles))
	for _, p := range profiles {
		userIDs = append(userIDs, p.UserID)
	}

	photoByUserID := getProfilePhotosByUserID(userIDs)
	ratingByUserID := getTradespersonRatings(userIDs)
	completedJobsByUserID := getCompletedBookingCountsByColumn("tradesperson_id", userIDs)

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		name := strings.TrimSpace(p.FirstName + " " + p.LastName)
		if name == "" {
			name = "Tradesperson"
		}

		specializations := decodeStringList(p.Specializations)
		specializationLabel := strings.TrimSpace(p.TradeCategory)
		if len(specializations) > 0 {
			specializationLabel = strings.Join(specializations, ", ")
		}

		ratingMeta := ratingByUserID[p.UserID]
		rows = append(rows, map[string]any{
			"id":                p.UserID,
			"tradesperson_id":   p.UserID,
			"profile_id":        p.ID,
			"name":              name,
			"first_name":        p.FirstName,
			"last_name":         p.LastName,
			"trade":             p.TradeCategory,
			"trade_category":    p.TradeCategory,
			"specialization":    specializationLabel,
			"specializations":   specializations,
			"rating":            ratingMeta.AvgRating,
			"reviews":           ratingMeta.ReviewCount,
			"review_count":      ratingMeta.ReviewCount,
			"completed_jobs":    completedJobsByUserID[p.UserID],
			"completedJobs":     completedJobsByUserID[p.UserID],
			"barangay":          p.ServiceBarangay,
			"is_on_duty":        p.IsOnDuty,
			"isOnDuty":          p.IsOnDuty,
			"avatar":            initialsFromName(p.FirstName, p.LastName, "TP"),
			"experience":        fmt.Sprintf("%d years", p.YearsExperience),
			"experience_years":  p.YearsExperience,
			"bio":               p.Bio,
			"profile_image_url": buildPublicUploadURL(r, photoByUserID[p.UserID].FilePath),
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"tradespeople": rows})
}

func BookingsRoot(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		listAdminBookings(w, r)
		return
	}

	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	var req createBookingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.TradespersonID == 0 {
		writeError(w, http.StatusBadRequest, "tradesperson_id is required")
		return
	}
	if strings.TrimSpace(req.ProblemDescription) == "" {
		writeError(w, http.StatusBadRequest, "problem_description is required")
		return
	}
	if strings.TrimSpace(req.Address) == "" {
		writeError(w, http.StatusBadRequest, "address is required")
		return
	}
	if strings.TrimSpace(req.Date) == "" || strings.TrimSpace(req.Time) == "" {
		writeError(w, http.StatusBadRequest, "date and time are required")
		return
	}

	// Validate booking schedule (must be at least 40 minutes in advance)
	scheduledTime, err := services.ParseScheduledTime(strings.TrimSpace(req.Date), strings.TrimSpace(req.Time))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid date or time format")
		return
	}
	if err := services.ValidateBookingSchedule(scheduledTime); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	var tradesperson models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", req.TradespersonID).First(&tradesperson).Error; err != nil {
		writeError(w, http.StatusNotFound, "tradesperson not found")
		return
	}
	if tradesperson.VerificationStatus != "approved" {
		writeError(w, http.StatusConflict, "tradesperson is not yet approved")
		return
	}
	if !tradesperson.IsOnDuty {
		writeError(w, http.StatusConflict, "tradesperson is currently off duty")
		return
	}

	tradeCategory := strings.TrimSpace(req.TradeCategory)
	if tradeCategory == "" {
		tradeCategory = tradesperson.TradeCategory
	}

	// Compute expiration time based on acceptance window and pre-scheduled cutoff
	expirationTime, err := services.ComputeExpirationTime(time.Now(), strings.TrimSpace(req.Date), strings.TrimSpace(req.Time))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to compute expiration time")
		return
	}

	booking := models.Booking{
		HomeownerID:        homeownerID,
		TradespersonID:     req.TradespersonID,
		TradeCategory:      tradeCategory,
		Specialization:     strings.TrimSpace(req.Specialization),
		ProblemDescription: strings.TrimSpace(req.ProblemDescription),
		Address:            strings.TrimSpace(req.Address),
		PreferredDate:      strings.TrimSpace(req.Date),
		PreferredTime:      strings.TrimSpace(req.Time),
		OfferedBudget:      req.OfferedBudget,
		Status:             "Pending",
		ExpirationTime:     &expirationTime,
	}

	if err := config.DB.Create(&booking).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create booking")
		return
	}

	bookingID := booking.ID
	if _, err := getOrCreateConversation(homeownerID, req.TradespersonID, &bookingID); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to initialize conversation")
		return
	}

	resp := buildBookingResponse(r, booking, tradesperson, models.UserProfilePhoto{}, nil)
	writeJSON(w, http.StatusCreated, map[string]any{"booking": resp})
}

func listAdminBookings(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	role, _ := claims["role"].(string)
	if role != "admin" {
		writeError(w, http.StatusForbidden, "admin access required")
		return
	}

	var bookings []models.Booking
	if err := config.DB.Order("created_at desc").Find(&bookings).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list bookings")
		return
	}

	rows := make([]map[string]any, 0, len(bookings))
	for _, booking := range bookings {
		rows = append(rows, map[string]any{
			"id":                  booking.ID,
			"homeowner_id":        booking.HomeownerID,
			"tradesperson_id":     booking.TradespersonID,
			"trade_category":      booking.TradeCategory,
			"specialization":      booking.Specialization,
			"status":              booking.Status,
			"created_at":          booking.CreatedAt,
			"updated_at":          booking.UpdatedAt,
			"cancelled_at":        booking.CancelledAt,
			"cancellation_reason": booking.CancellationReason,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"bookings": rows})
}

func HomeownerBookings(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	var bookings []models.Booking
	if err := config.DB.Where("homeowner_id = ?", homeownerID).Order("created_at DESC").Find(&bookings).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list bookings")
		return
	}

	if len(bookings) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"bookings": []map[string]any{}})
		return
	}

	tradespersonIDs := make([]uint, 0, len(bookings))
	bookingIDs := make([]uint, 0, len(bookings))
	for _, b := range bookings {
		tradespersonIDs = append(tradespersonIDs, b.TradespersonID)
		bookingIDs = append(bookingIDs, b.ID)
	}

	profileByUserID := getTradespersonProfilesByUserID(tradespersonIDs)
	photoByUserID := getProfilePhotosByUserID(tradespersonIDs)
	reviewByBookingID := getReviewsByBookingID(bookingIDs)

	rows := make([]map[string]any, 0, len(bookings))
	for _, b := range bookings {
		rows = append(rows, buildBookingResponse(r, b, profileByUserID[b.TradespersonID], photoByUserID[b.TradespersonID], reviewByBookingID[b.ID]))
	}

	writeJSON(w, http.StatusOK, map[string]any{"bookings": rows})
}

func BookingByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 3 || parts[0] != "api" || parts[1] != "bookings" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	bookingID, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil || bookingID == 0 {
		writeError(w, http.StatusBadRequest, "invalid booking id")
		return
	}

	if len(parts) == 3 {
		switch r.Method {
		case http.MethodGet:
			getBookingByID(w, r, uint(bookingID))
		case http.MethodPatch:
			updateBookingByID(w, r, uint(bookingID))
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
		return
	}

	if len(parts) == 4 {
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}

		switch parts[3] {
		case "cancel":
			cancelBookingByID(w, r, uint(bookingID))
		case "review":
			reviewBookingByID(w, r, uint(bookingID))
		case "issues":
			reportBookingIssueByID(w, r, uint(bookingID))
		default:
			writeError(w, http.StatusNotFound, "not found")
		}
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func getBookingByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	booking, found := getOwnedBooking(w, homeownerID, bookingID)
	if !found {
		return
	}

	var profile models.TradespersonProfile
	config.DB.Where("user_id = ?", booking.TradespersonID).First(&profile)

	var photo models.UserProfilePhoto
	config.DB.Where("user_id = ?", booking.TradespersonID).First(&photo)

	var review models.BookingReview
	if err := config.DB.Where("booking_id = ?", booking.ID).First(&review).Error; err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"booking": buildBookingResponse(r, booking, profile, photo, nil)})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"booking": buildBookingResponse(r, booking, profile, photo, &review)})
}

func updateBookingByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	booking, found := getOwnedBooking(w, homeownerID, bookingID)
	if !found {
		return
	}

	if booking.Status != "Pending" {
		writeError(w, http.StatusConflict, "only pending bookings can be edited")
		return
	}

	var req updateBookingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	updates := map[string]any{}
	if req.Specialization != nil {
		updates["specialization"] = strings.TrimSpace(*req.Specialization)
	}
	if req.ProblemDescription != nil {
		value := strings.TrimSpace(*req.ProblemDescription)
		if value == "" {
			writeError(w, http.StatusBadRequest, "problem_description cannot be empty")
			return
		}
		updates["problem_description"] = value
	}
	if req.Address != nil {
		value := strings.TrimSpace(*req.Address)
		if value == "" {
			writeError(w, http.StatusBadRequest, "address cannot be empty")
			return
		}
		updates["address"] = value
	}
	if req.Date != nil {
		value := strings.TrimSpace(*req.Date)
		if value == "" {
			writeError(w, http.StatusBadRequest, "date cannot be empty")
			return
		}
		updates["preferred_date"] = value
	}
	if req.Time != nil {
		value := strings.TrimSpace(*req.Time)
		if value == "" {
			writeError(w, http.StatusBadRequest, "time cannot be empty")
			return
		}
		updates["preferred_time"] = value
	}
	if req.OfferedBudget != nil {
		if *req.OfferedBudget < 0 {
			writeError(w, http.StatusBadRequest, "offered_budget cannot be negative")
			return
		}
		updates["offered_budget"] = *req.OfferedBudget
	}

	if len(updates) == 0 {
		writeError(w, http.StatusBadRequest, "no updates provided")
		return
	}

	if err := config.DB.Model(&booking).Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update booking")
		return
	}

	var refreshed models.Booking
	if err := config.DB.First(&refreshed, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated booking")
		return
	}

	var profile models.TradespersonProfile
	config.DB.Where("user_id = ?", refreshed.TradespersonID).First(&profile)

	var photo models.UserProfilePhoto
	config.DB.Where("user_id = ?", refreshed.TradespersonID).First(&photo)

	writeJSON(w, http.StatusOK, map[string]any{"booking": buildBookingResponse(r, refreshed, profile, photo, nil)})
}

func cancelBookingByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	booking, found := getOwnedBooking(w, homeownerID, bookingID)
	if !found {
		return
	}

	if booking.Status == "Cancelled" {
		writeJSON(w, http.StatusOK, map[string]any{"message": "booking already cancelled"})
		return
	}
	if booking.Status != "Pending" && booking.Status != "Accepted" {
		writeError(w, http.StatusConflict, "booking cannot be cancelled in its current status")
		return
	}

	now := time.Now()
	if err := config.DB.Model(&booking).Updates(map[string]any{"status": "Cancelled", "cancelled_at": &now}).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to cancel booking")
		return
	}

	var refreshed models.Booking
	if err := config.DB.First(&refreshed, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated booking")
		return
	}

	var profile models.TradespersonProfile
	config.DB.Where("user_id = ?", refreshed.TradespersonID).First(&profile)

	var photo models.UserProfilePhoto
	config.DB.Where("user_id = ?", refreshed.TradespersonID).First(&photo)

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "booking cancelled",
		"booking": buildBookingResponse(r, refreshed, profile, photo, nil),
	})
}

func reviewBookingByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	booking, found := getOwnedBooking(w, homeownerID, bookingID)
	if !found {
		return
	}

	if booking.Status != "Completed" {
		writeError(w, http.StatusConflict, "only completed bookings can be reviewed")
		return
	}

	var req reviewBookingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Rating < 1 || req.Rating > 5 {
		writeError(w, http.StatusBadRequest, "rating must be between 1 and 5")
		return
	}

	var existing models.BookingReview
	if err := config.DB.Where("booking_id = ?", booking.ID).First(&existing).Error; err == nil {
		writeError(w, http.StatusConflict, "booking has already been reviewed")
		return
	}

	tagsJSON, _ := json.Marshal(req.Tags)
	review := models.BookingReview{
		BookingID:      booking.ID,
		HomeownerID:    homeownerID,
		TradespersonID: booking.TradespersonID,
		Rating:         req.Rating,
		Comment:        strings.TrimSpace(req.Comment),
		Tags:           string(tagsJSON),
	}

	if err := config.DB.Create(&review).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to submit review")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": "review submitted",
		"review": map[string]any{
			"booking_id": booking.ID,
			"rating":     review.Rating,
			"comment":    review.Comment,
			"tags":       req.Tags,
		},
	})
}

func reportBookingIssueByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	booking, found := getOwnedBooking(w, homeownerID, bookingID)
	if !found {
		return
	}

	var req reportBookingIssueRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	category := strings.TrimSpace(req.Category)
	details := strings.TrimSpace(req.Details)
	if category == "" || details == "" {
		writeError(w, http.StatusBadRequest, "category and details are required")
		return
	}

	issue := models.BookingIssue{
		BookingID:   booking.ID,
		HomeownerID: homeownerID,
		Category:    category,
		Details:     details,
		Status:      "Under Review",
	}

	if err := config.DB.Create(&issue).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to submit issue")
		return
	}

	if booking.Status != "Under Review" {
		_ = config.DB.Model(&booking).Update("status", "Under Review").Error
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": "issue submitted",
		"issue": map[string]any{
			"id":         issue.ID,
			"booking_id": issue.BookingID,
			"category":   issue.Category,
			"details":    issue.Details,
			"status":     issue.Status,
			"created_at": issue.CreatedAt,
		},
	})
}

func getOwnedBooking(w http.ResponseWriter, homeownerID uint, bookingID uint) (models.Booking, bool) {
	var booking models.Booking
	if err := config.DB.Where("id = ? AND homeowner_id = ?", bookingID, homeownerID).First(&booking).Error; err != nil {
		writeError(w, http.StatusNotFound, "booking not found")
		return models.Booking{}, false
	}

	return booking, true
}

func requireHomeowner(w http.ResponseWriter, r *http.Request) (uint, bool) {
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

	role, _ := claims["role"].(string)
	if role != "homeowner" {
		writeError(w, http.StatusForbidden, "homeowner access required")
		return 0, false
	}

	return uint(userIDFloat), true
}

func buildBookingResponse(
	r *http.Request,
	booking models.Booking,
	tradespersonProfile models.TradespersonProfile,
	photo models.UserProfilePhoto,
	review *models.BookingReview,
) map[string]any {
	tradespersonName := strings.TrimSpace(tradespersonProfile.FirstName + " " + tradespersonProfile.LastName)
	if tradespersonName == "" {
		tradespersonName = "Tradesperson"
	}

	avatar := initialsFromName(tradespersonProfile.FirstName, tradespersonProfile.LastName, "TP")

	isReviewed := review != nil
	var reviewRating any = nil
	var reviewComment any = nil
	reviewTags := []string{}
	if review != nil {
		reviewRating = review.Rating
		reviewComment = review.Comment
		reviewTags = decodeTagsJSON(review.Tags)
	}

	var expirationTime any = nil
	if booking.ExpirationTime != nil {
		expirationTime = booking.ExpirationTime
	}

	return map[string]any{
		"id":                             booking.ID,
		"reference_id":                   fmt.Sprintf("BK-%06d", booking.ID),
		"tradesperson_id":                booking.TradespersonID,
		"tradesperson_name":              tradespersonName,
		"tradesperson_avatar":            avatar,
		"tradesperson_profile_image_url": buildPublicUploadURL(r, photo.FilePath),
		"trade":                          booking.TradeCategory,
		"trade_category":                 booking.TradeCategory,
		"specialization":                 booking.Specialization,
		"problem_description":            booking.ProblemDescription,
		"problemDescription":             booking.ProblemDescription,
		"address":                        booking.Address,
		"date":                           booking.PreferredDate,
		"time":                           booking.PreferredTime,
		"offered_budget":                 booking.OfferedBudget,
		"offeredBudget":                  booking.OfferedBudget,
		"status":                         booking.Status,
		"cancelled_at":                   booking.CancelledAt,
		"completed_at":                   booking.CompletedAt,
		"cancellation_reason":            booking.CancellationReason,
		"created_at":                     booking.CreatedAt,
		"expiration_time":                expirationTime,
		"is_reviewed":                    isReviewed,
		"isReviewed":                     isReviewed,
		"review_rating":                  reviewRating,
		"review_comment":                 reviewComment,
		"review_tags":                    reviewTags,
	}
}

func getTradespersonProfilesByUserID(userIDs []uint) map[uint]models.TradespersonProfile {
	out := map[uint]models.TradespersonProfile{}
	if len(userIDs) == 0 {
		return out
	}

	var profiles []models.TradespersonProfile
	if err := config.DB.Where("user_id IN ?", userIDs).Find(&profiles).Error; err != nil {
		return out
	}

	for _, p := range profiles {
		out[p.UserID] = p
	}

	return out
}

func getProfilePhotosByUserID(userIDs []uint) map[uint]models.UserProfilePhoto {
	out := map[uint]models.UserProfilePhoto{}
	if len(userIDs) == 0 {
		return out
	}

	var photos []models.UserProfilePhoto
	if err := config.DB.Where("user_id IN ?", userIDs).Find(&photos).Error; err != nil {
		return out
	}

	for _, p := range photos {
		out[p.UserID] = p
	}

	return out
}

type tradespersonRatingMeta struct {
	AvgRating   float64
	ReviewCount int64
}

func getTradespersonRatings(userIDs []uint) map[uint]tradespersonRatingMeta {
	out := map[uint]tradespersonRatingMeta{}
	if len(userIDs) == 0 {
		return out
	}

	type row struct {
		TradespersonID uint
		AvgRating      float64
		ReviewCount    int64
	}

	var rows []row
	err := config.DB.Table("booking_reviews").
		Select("tradesperson_id, COALESCE(AVG(rating), 0) AS avg_rating, COUNT(*) AS review_count").
		Where("tradesperson_id IN ?", userIDs).
		Group("tradesperson_id").
		Scan(&rows).Error
	if err != nil {
		return out
	}

	for _, r := range rows {
		out[r.TradespersonID] = tradespersonRatingMeta{AvgRating: r.AvgRating, ReviewCount: r.ReviewCount}
	}

	return out
}

func getCompletedBookingCountsByColumn(column string, userIDs []uint) map[uint]int64 {
	out := map[uint]int64{}
	if len(userIDs) == 0 {
		return out
	}

	type row struct {
		UserID uint
		Count  int64
	}

	var rows []row
	if err := config.DB.Model(&models.Booking{}).
		Select(column+" AS user_id, COUNT(*) AS count").
		Where(column+" IN ? AND status = ?", userIDs, "Completed").
		Group(column).
		Scan(&rows).Error; err != nil {
		return out
	}

	for _, row := range rows {
		out[row.UserID] = row.Count
	}

	return out
}

func getReviewsByBookingID(bookingIDs []uint) map[uint]*models.BookingReview {
	out := map[uint]*models.BookingReview{}
	if len(bookingIDs) == 0 {
		return out
	}

	var reviews []models.BookingReview
	if err := config.DB.Where("booking_id IN ?", bookingIDs).Find(&reviews).Error; err != nil {
		return out
	}

	for i := range reviews {
		review := reviews[i]
		out[review.BookingID] = &review
	}

	return out
}

func decodeTagsJSON(raw string) []string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return []string{}
	}

	var tags []string
	if err := json.Unmarshal([]byte(trimmed), &tags); err == nil {
		return tags
	}

	chunks := strings.Split(trimmed, ",")
	out := make([]string, 0, len(chunks))
	for _, c := range chunks {
		v := strings.TrimSpace(c)
		if v != "" {
			out = append(out, v)
		}
	}

	return out
}

func parseBoolQuery(raw string) (bool, bool) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "1", "true", "yes", "on":
		return true, true
	case "0", "false", "no", "off":
		return false, true
	default:
		return false, false
	}
}

func parseAnyBool(raw any) (bool, bool) {
	switch v := raw.(type) {
	case bool:
		return v, true
	case string:
		return parseBoolQuery(v)
	case float64:
		if v == 1 {
			return true, true
		}
		if v == 0 {
			return false, true
		}
	}

	return false, false
}

func initialsFromName(firstName string, lastName string, fallback string) string {
	f := strings.TrimSpace(firstName)
	l := strings.TrimSpace(lastName)
	if f == "" && l == "" {
		return fallback
	}

	first := ""
	last := ""
	if f != "" {
		first = strings.ToUpper(string([]rune(f)[0]))
	}
	if l != "" {
		last = strings.ToUpper(string([]rune(l)[0]))
	}

	initials := strings.TrimSpace(first + last)
	if initials == "" {
		return fallback
	}

	return initials
}

func buildPublicUploadURL(r *http.Request, filePath string) string {
	trimmed := strings.TrimPrefix(filepath.ToSlash(strings.TrimSpace(filePath)), "uploads/")
	if trimmed == "" {
		return ""
	}

	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-Proto")); forwarded != "" {
		scheme = forwarded
	}

	return scheme + "://" + r.Host + "/uploads/" + trimmed
}

func requireTradesperson(w http.ResponseWriter, r *http.Request) (uint, bool) {
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

	role, _ := claims["role"].(string)
	if role != "tradesperson" {
		writeError(w, http.StatusForbidden, "tradesperson access required")
		return 0, false
	}

	return uint(userIDFloat), true
}

func getTradespersonOwnedBooking(w http.ResponseWriter, tradespersonID uint, bookingID uint) (models.Booking, bool) {
	var booking models.Booking
	if err := config.DB.Where("id = ? AND tradesperson_id = ?", bookingID, tradespersonID).First(&booking).Error; err != nil {
		writeError(w, http.StatusNotFound, "booking not found")
		return models.Booking{}, false
	}

	return booking, true
}

func getHomeownerProfilesByUserID(userIDs []uint) map[uint]models.HomeownerProfile {
	out := map[uint]models.HomeownerProfile{}
	if len(userIDs) == 0 {
		return out
	}

	var profiles []models.HomeownerProfile
	if err := config.DB.Where("user_id IN ?", userIDs).Find(&profiles).Error; err != nil {
		return out
	}

	for _, p := range profiles {
		out[p.UserID] = p
	}

	return out
}

func urgencyFromBudget(budget float64) string {
	if budget >= 1000 {
		return "High"
	}
	if budget >= 500 {
		return "Medium"
	}

	return "Low"
}

func relativeTimeLabel(t time.Time) string {
	if t.IsZero() {
		return ""
	}

	delta := time.Since(t)
	if delta < time.Minute {
		return "Just now"
	}
	if delta < time.Hour {
		minutes := int(delta.Minutes())
		if minutes <= 1 {
			return "1 min ago"
		}
		return fmt.Sprintf("%d mins ago", minutes)
	}
	if delta < 24*time.Hour {
		hours := int(delta.Hours())
		if hours <= 1 {
			return "1 hour ago"
		}
		return fmt.Sprintf("%d hours ago", hours)
	}

	days := int(delta.Hours() / 24)
	if days <= 1 {
		return "1 day ago"
	}
	if days <= 7 {
		return fmt.Sprintf("%d days ago", days)
	}

	return t.Format("Jan 2, 2006")
}

func buildTradespersonRequestResponse(
	r *http.Request,
	booking models.Booking,
	homeownerProfile models.HomeownerProfile,
	photo models.UserProfilePhoto,
) map[string]any {
	homeownerName := strings.TrimSpace(homeownerProfile.FirstName + " " + homeownerProfile.LastName)
	if homeownerName == "" {
		homeownerName = "Homeowner"
	}

	service := strings.TrimSpace(booking.Specialization)
	if service == "" {
		service = booking.TradeCategory
	}

	urgency := urgencyFromBudget(booking.OfferedBudget)

	return map[string]any{
		"id":                          booking.ID,
		"reference_id":                fmt.Sprintf("REQ-%06d", booking.ID),
		"booking_id":                  booking.ID,
		"homeowner_id":                booking.HomeownerID,
		"homeowner_name":              homeownerName,
		"homeowner_avatar":            initialsFromName(homeownerProfile.FirstName, homeownerProfile.LastName, "HO"),
		"homeowner_profile_image_url": buildPublicUploadURL(r, photo.FilePath),
		"trade":                       booking.TradeCategory,
		"trade_category":              booking.TradeCategory,
		"specialization":              booking.Specialization,
		"service":                     service,
		"problem_description":         booking.ProblemDescription,
		"address":                     booking.Address,
		"barangay":                    homeownerProfile.Barangay,
		"date":                        booking.PreferredDate,
		"time":                        booking.PreferredTime,
		"offered_budget":              booking.OfferedBudget,
		"budget":                      booking.OfferedBudget,
		"urgency":                     urgency,
		"status":                      booking.Status,
		"created_at":                  booking.CreatedAt,
		"posted_at":                   relativeTimeLabel(booking.CreatedAt),
		"is_new":                      time.Since(booking.CreatedAt) <= 24*time.Hour,
	}
}

func buildTradespersonJobResponse(
	r *http.Request,
	booking models.Booking,
	homeownerProfile models.HomeownerProfile,
	photo models.UserProfilePhoto,
	review *models.BookingReview,
) map[string]any {
	homeownerName := strings.TrimSpace(homeownerProfile.FirstName + " " + homeownerProfile.LastName)
	if homeownerName == "" {
		homeownerName = "Homeowner"
	}

	service := strings.TrimSpace(booking.Specialization)
	if service == "" {
		service = booking.TradeCategory
	}

	var rating any = nil
	if review != nil {
		rating = review.Rating
	}

	return map[string]any{
		"id":                          booking.ID,
		"reference_id":                fmt.Sprintf("BK-%06d", booking.ID),
		"booking_id":                  booking.ID,
		"homeowner_id":                booking.HomeownerID,
		"homeowner_name":              homeownerName,
		"homeowner_avatar":            initialsFromName(homeownerProfile.FirstName, homeownerProfile.LastName, "HO"),
		"homeowner_profile_image_url": buildPublicUploadURL(r, photo.FilePath),
		"trade":                       booking.TradeCategory,
		"trade_category":              booking.TradeCategory,
		"specialization":              booking.Specialization,
		"service":                     service,
		"problem_description":         booking.ProblemDescription,
		"address":                     booking.Address,
		"barangay":                    homeownerProfile.Barangay,
		"date":                        booking.PreferredDate,
		"time":                        booking.PreferredTime,
		"offered_budget":              booking.OfferedBudget,
		"budget":                      booking.OfferedBudget,
		"status":                      booking.Status,
		"rating":                      rating,
		"cancelled_at":                booking.CancelledAt,
		"completed_at":                booking.CompletedAt,
		"created_at":                  booking.CreatedAt,
		"updated_at":                  booking.UpdatedAt,
	}
}

func UpdateMyOnDutyStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var req updateOnDutyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	isOnDuty := false
	if req.IsOnDuty != nil {
		isOnDuty = *req.IsOnDuty
	} else if req.IsOnDuty2 != nil {
		isOnDuty = *req.IsOnDuty2
	} else {
		writeError(w, http.StatusBadRequest, "is_on_duty is required")
		return
	}

	var profile models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", tradespersonID).First(&profile).Error; err != nil {
		writeError(w, http.StatusNotFound, "tradesperson profile not found")
		return
	}

	if err := config.DB.Model(&profile).Update("is_on_duty", isOnDuty).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update on-duty status")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":    "on-duty status updated",
		"is_on_duty": isOnDuty,
		"isOnDuty":   isOnDuty,
	})
}

func TradespersonIncomingRequests(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var bookings []models.Booking
	if err := config.DB.Where("tradesperson_id = ? AND status = ?", tradespersonID, "Pending").Order("created_at DESC").Find(&bookings).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list incoming requests")
		return
	}

	if len(bookings) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"requests": []map[string]any{}})
		return
	}

	homeownerIDs := make([]uint, 0, len(bookings))
	for _, b := range bookings {
		homeownerIDs = append(homeownerIDs, b.HomeownerID)
	}

	homeownerProfiles := getHomeownerProfilesByUserID(homeownerIDs)
	homeownerPhotos := getProfilePhotosByUserID(homeownerIDs)

	rows := make([]map[string]any, 0, len(bookings))
	for _, b := range bookings {
		rows = append(rows, buildTradespersonRequestResponse(r, b, homeownerProfiles[b.HomeownerID], homeownerPhotos[b.HomeownerID]))
	}

	writeJSON(w, http.StatusOK, map[string]any{"requests": rows})
}

func TradespersonRequestByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 4 || parts[0] != "api" || parts[1] != "requests" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	bookingID, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil || bookingID == 0 {
		writeError(w, http.StatusBadRequest, "invalid request id")
		return
	}

	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	switch parts[3] {
	case "accept":
		acceptTradespersonRequestByID(w, r, uint(bookingID))
	case "decline":
		declineTradespersonRequestByID(w, r, uint(bookingID))
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
}

func acceptTradespersonRequestByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	booking, found := getTradespersonOwnedBooking(w, tradespersonID, bookingID)
	if !found {
		return
	}

	if booking.Status != "Pending" {
		writeError(w, http.StatusConflict, "only pending requests can be accepted")
		return
	}

	err := config.DB.Transaction(func(tx *gorm.DB) error {
		var slotAlreadyTaken int64
		if err := tx.Model(&models.Booking{}).
			Where(
				"tradesperson_id = ? AND preferred_date = ? AND preferred_time = ? AND id <> ? AND status IN ?",
				tradespersonID,
				booking.PreferredDate,
				booking.PreferredTime,
				booking.ID,
				[]string{"Accepted", "In Progress"},
			).
			Count(&slotAlreadyTaken).Error; err != nil {
			return err
		}
		if slotAlreadyTaken > 0 {
			return fmt.Errorf("time slot already taken")
		}

		if err := tx.Model(&booking).Update("status", "Accepted").Error; err != nil {
			return err
		}

		now := time.Now()
		if err := tx.Model(&models.Booking{}).
			Where(
				"tradesperson_id = ? AND preferred_date = ? AND preferred_time = ? AND id <> ? AND status = ?",
				tradespersonID,
				booking.PreferredDate,
				booking.PreferredTime,
				booking.ID,
				"Pending",
			).
			Updates(map[string]any{
				"status":              "Cancelled",
				"cancelled_at":        &now,
				"cancellation_reason": "Auto-cancelled: the tradesperson accepted another booking for this date and time.",
			}).Error; err != nil {
			return err
		}

		return nil
	})
	if err != nil {
		if err.Error() == "time slot already taken" {
			writeError(w, http.StatusConflict, "time slot already has an accepted job")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to accept request")
		return
	}

	var refreshed models.Booking
	if err := config.DB.First(&refreshed, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated request")
		return
	}

	homeownerProfile := getHomeownerProfilesByUserID([]uint{refreshed.HomeownerID})
	homeownerPhotos := getProfilePhotosByUserID([]uint{refreshed.HomeownerID})

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "request accepted",
		"job":     buildTradespersonJobResponse(r, refreshed, homeownerProfile[refreshed.HomeownerID], homeownerPhotos[refreshed.HomeownerID], nil),
	})
}

func declineTradespersonRequestByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	booking, found := getTradespersonOwnedBooking(w, tradespersonID, bookingID)
	if !found {
		return
	}

	if booking.Status != "Pending" {
		writeError(w, http.StatusConflict, "only pending requests can be declined")
		return
	}

	now := time.Now()
	if err := config.DB.Model(&booking).Updates(map[string]any{"status": "Cancelled", "cancelled_at": &now}).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to decline request")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"message": "request declined"})
}

func TradespersonJobs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var jobs []models.Booking
	if err := config.DB.Where("tradesperson_id = ? AND status <> ?", tradespersonID, "Pending").Order("created_at DESC").Find(&jobs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list jobs")
		return
	}

	if len(jobs) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{"jobs": []map[string]any{}})
		return
	}

	homeownerIDs := make([]uint, 0, len(jobs))
	bookingIDs := make([]uint, 0, len(jobs))
	for _, b := range jobs {
		homeownerIDs = append(homeownerIDs, b.HomeownerID)
		bookingIDs = append(bookingIDs, b.ID)
	}

	homeownerProfiles := getHomeownerProfilesByUserID(homeownerIDs)
	homeownerPhotos := getProfilePhotosByUserID(homeownerIDs)
	reviewByBookingID := getReviewsByBookingID(bookingIDs)

	rows := make([]map[string]any, 0, len(jobs))
	for _, b := range jobs {
		rows = append(rows, buildTradespersonJobResponse(r, b, homeownerProfiles[b.HomeownerID], homeownerPhotos[b.HomeownerID], reviewByBookingID[b.ID]))
	}

	writeJSON(w, http.StatusOK, map[string]any{"jobs": rows})
}

func TradespersonJobByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 3 || parts[0] != "api" || parts[1] != "jobs" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	bookingID, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil || bookingID == 0 {
		writeError(w, http.StatusBadRequest, "invalid job id")
		return
	}

	if len(parts) == 3 {
		if r.Method != http.MethodGet {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}

		getTradespersonJobByID(w, r, uint(bookingID))
		return
	}

	if len(parts) == 4 {
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}

		switch parts[3] {
		case "start":
			startTradespersonJobByID(w, r, uint(bookingID))
		case "complete":
			completeTradespersonJobByID(w, r, uint(bookingID))
		default:
			writeError(w, http.StatusNotFound, "not found")
		}
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func getTradespersonJobByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	booking, found := getTradespersonOwnedBooking(w, tradespersonID, bookingID)
	if !found {
		return
	}

	if booking.Status == "Pending" {
		writeError(w, http.StatusConflict, "request has not been accepted yet")
		return
	}

	homeownerProfile := getHomeownerProfilesByUserID([]uint{booking.HomeownerID})
	homeownerPhotos := getProfilePhotosByUserID([]uint{booking.HomeownerID})
	reviewByBookingID := getReviewsByBookingID([]uint{booking.ID})

	writeJSON(w, http.StatusOK, map[string]any{
		"job": buildTradespersonJobResponse(r, booking, homeownerProfile[booking.HomeownerID], homeownerPhotos[booking.HomeownerID], reviewByBookingID[booking.ID]),
	})
}

func startTradespersonJobByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	booking, found := getTradespersonOwnedBooking(w, tradespersonID, bookingID)
	if !found {
		return
	}

	if booking.Status != "Accepted" {
		writeError(w, http.StatusConflict, "only accepted jobs can be started")
		return
	}

	var inProgressCount int64
	if err := config.DB.Model(&models.Booking{}).
		Where("tradesperson_id = ? AND status = ? AND id <> ?", tradespersonID, "In Progress", booking.ID).
		Count(&inProgressCount).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to validate active jobs")
		return
	}

	if inProgressCount > 0 {
		writeError(w, http.StatusConflict, "you can only have one in-progress job at a time")
		return
	}

	if err := config.DB.Model(&booking).Update("status", "In Progress").Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to start job")
		return
	}

	var refreshed models.Booking
	if err := config.DB.First(&refreshed, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated job")
		return
	}

	homeownerProfile := getHomeownerProfilesByUserID([]uint{refreshed.HomeownerID})
	homeownerPhotos := getProfilePhotosByUserID([]uint{refreshed.HomeownerID})

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "job started",
		"job":     buildTradespersonJobResponse(r, refreshed, homeownerProfile[refreshed.HomeownerID], homeownerPhotos[refreshed.HomeownerID], nil),
	})
}

func completeTradespersonJobByID(w http.ResponseWriter, r *http.Request, bookingID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	booking, found := getTradespersonOwnedBooking(w, tradespersonID, bookingID)
	if !found {
		return
	}

	if booking.Status != "In Progress" {
		writeError(w, http.StatusConflict, "only in-progress jobs can be completed")
		return
	}

	completedAt := time.Now()
	if err := config.DB.Model(&booking).Updates(map[string]any{
		"status":       "Completed",
		"completed_at": completedAt,
	}).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to complete job")
		return
	}

	var refreshed models.Booking
	if err := config.DB.First(&refreshed, booking.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated job")
		return
	}

	homeownerProfile := getHomeownerProfilesByUserID([]uint{refreshed.HomeownerID})
	homeownerPhotos := getProfilePhotosByUserID([]uint{refreshed.HomeownerID})

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "job completed",
		"job":     buildTradespersonJobResponse(r, refreshed, homeownerProfile[refreshed.HomeownerID], homeownerPhotos[refreshed.HomeownerID], nil),
	})
}
