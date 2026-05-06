package controllers

import (
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"
	"fixit-backend/services"
)

func TradespersonMyReviews(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var reviews []models.BookingReview
	if err := config.DB.Where("tradesperson_id = ?", tradespersonID).Find(&reviews).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load reviews")
		return
	}

	var bookings []models.Booking
	if err := config.DB.Where("tradesperson_id = ?", tradespersonID).Find(&bookings).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load performance data")
		return
	}

	ratingFilter, hasRatingFilter := parseReviewRatingFilter(r.URL.Query().Get("rating"))
	tagFilter := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("tag")))
	sortBy := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("sort")))
	if sortBy == "" {
		sortBy = "recent"
	}

	filtered := make([]models.BookingReview, 0, len(reviews))
	for _, review := range reviews {
		if hasRatingFilter && int(review.Rating+0.5) != ratingFilter {
			continue
		}

		tags := decodeTagsJSON(review.Tags)
		if tagFilter != "" && !tagsContain(tags, tagFilter) {
			continue
		}

		filtered = append(filtered, review)
	}

	sort.Slice(filtered, func(i, j int) bool {
		switch sortBy {
		case "highest":
			if filtered[i].Rating == filtered[j].Rating {
				return filtered[i].CreatedAt.After(filtered[j].CreatedAt)
			}
			return filtered[i].Rating > filtered[j].Rating
		case "lowest":
			if filtered[i].Rating == filtered[j].Rating {
				return filtered[i].CreatedAt.After(filtered[j].CreatedAt)
			}
			return filtered[i].Rating < filtered[j].Rating
		default:
			return filtered[i].CreatedAt.After(filtered[j].CreatedAt)
		}
	})

	bookingIDs := make([]uint, 0, len(filtered))
	homeownerIDs := make([]uint, 0, len(filtered))
	for _, review := range filtered {
		bookingIDs = append(bookingIDs, review.BookingID)
		homeownerIDs = append(homeownerIDs, review.HomeownerID)
	}

	bookingsByID := getBookingsByID(bookingIDs)
	homeownersByID := getHomeownerProfilesByUserID(homeownerIDs)
	photosByUserID := getProfilePhotosByUserID(homeownerIDs)

	rows := make([]map[string]any, 0, len(filtered))
	for _, review := range filtered {
		booking := bookingsByID[review.BookingID]
		homeowner := homeownersByID[review.HomeownerID]
		photo := photosByUserID[review.HomeownerID]

		homeownerName := strings.TrimSpace(homeowner.FirstName + " " + homeowner.LastName)
		if homeownerName == "" {
			homeownerName = "Homeowner"
		}

		service := strings.TrimSpace(booking.Specialization)
		if service == "" {
			service = booking.TradeCategory
		}

		rows = append(rows, map[string]any{
			"id":                          review.ID,
			"booking_id":                  review.BookingID,
			"homeowner_id":                review.HomeownerID,
			"homeowner_name":              homeownerName,
			"homeowner_avatar":            initialsFromName(homeowner.FirstName, homeowner.LastName, "HO"),
			"homeowner_profile_image_url": buildPublicUploadURL(r, photo.FilePath),
			"rating":                      review.Rating,
			"comment":                     review.Comment,
			"tags":                        decodeTagsJSON(review.Tags),
			"trade":                       booking.TradeCategory,
			"service":                     service,
			"barangay":                    homeowner.Barangay,
			"created_at":                  review.CreatedAt,
		})
	}

	summary := buildReviewSummary(reviews)
	summary["performance"] = buildPerformanceSummary(bookings, summary)
	writeJSON(w, http.StatusOK, map[string]any{
		"reviews": rows,
		"summary": summary,
	})
}

func buildReviewSummary(reviews []models.BookingReview) map[string]any {
	total := len(reviews)
	sum := 0.0
	distribution := map[string]int{"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}

	for _, review := range reviews {
		sum += review.Rating
		rounded := int(review.Rating + 0.5)
		if rounded < 1 {
			rounded = 1
		}
		if rounded > 5 {
			rounded = 5
		}
		key := strconv.Itoa(rounded)
		distribution[key] = distribution[key] + 1
	}

	avg := 0.0
	if total > 0 {
		avg = sum / float64(total)
	}

	return map[string]any{
		"average_rating": avg,
		"review_count":   total,
		"distribution":   distribution,
	}
}

func buildPerformanceSummary(bookings []models.Booking, reviewSummary map[string]any) map[string]any {
	responseEligibleCount := 0
	respondedCount := 0
	acceptedCount := 0
	completedCount := 0
	startedCount := 0
	onTimeCount := 0

	for _, booking := range bookings {
		if shouldCountBookingForResponse(booking) {
			responseEligibleCount++
			if bookingWasRespondedTo(booking) {
				respondedCount++
			}
		}

		if bookingWasAccepted(booking) {
			acceptedCount++
		}

		if bookingWasCompleted(booking) {
			completedCount++
		}

		if startedAt := bookingStartTime(booking); startedAt != nil {
			startedCount++
			if bookingStartedOnTime(booking, *startedAt) {
				onTimeCount++
			}
		}
	}

	customerSatisfaction := clampFloat(readFloatSummaryValue(reviewSummary, "average_rating"), 0, 5)
	reviewCount := readIntSummaryValue(reviewSummary, "review_count")
	responseRate := safeRatio(respondedCount, responseEligibleCount)
	completionRate := safeRatio(completedCount, acceptedCount)
	onTimeArrival := safeRatio(onTimeCount, startedCount)
	overallScore := weightedPerformanceScore(
		responseRate,
		responseEligibleCount > 0,
		completionRate,
		acceptedCount > 0,
		customerSatisfaction,
		reviewCount > 0,
		onTimeArrival,
		startedCount > 0,
	)

	return map[string]any{
		"response_rate":           responseRate,
		"completion_rate":         completionRate,
		"customer_satisfaction":   customerSatisfaction,
		"on_time_arrival":         onTimeArrival,
		"overall_score":           overallScore,
		"overall_label":           performanceLabel(overallScore),
		"response_rate_percent":   roundToWholePercent(responseRate),
		"completion_rate_percent": roundToWholePercent(completionRate),
		"on_time_arrival_percent": roundToWholePercent(onTimeArrival),
		"totals": map[string]any{
			"incoming_requests":  len(bookings),
			"response_eligible":  responseEligibleCount,
			"responded_requests": respondedCount,
			"accepted_jobs":      acceptedCount,
			"completed_jobs":     completedCount,
			"started_jobs":       startedCount,
			"on_time_jobs":       onTimeCount,
		},
	}
}

func shouldCountBookingForResponse(booking models.Booking) bool {
	if strings.EqualFold(strings.TrimSpace(booking.Status), "Pending") {
		return false
	}

	reason := normalizedCancellationReason(booking)
	if strings.HasPrefix(reason, "auto-cancelled:") && booking.RespondedAt == nil && booking.AcceptedAt == nil {
		return false
	}
	if reason == "cancelled_by_homeowner" && booking.RespondedAt == nil && booking.AcceptedAt == nil {
		return false
	}

	return true
}

func bookingWasRespondedTo(booking models.Booking) bool {
	if booking.RespondedAt != nil || booking.AcceptedAt != nil {
		return true
	}

	switch strings.ToLower(strings.TrimSpace(booking.Status)) {
	case "accepted", "in progress", "completed", "under review":
		return true
	case "cancelled":
		reason := normalizedCancellationReason(booking)
		if reason == "expired_unaccepted" {
			return false
		}
		if strings.HasPrefix(reason, "auto-cancelled:") {
			return false
		}
		if reason == "cancelled_by_homeowner" {
			return false
		}
		return true
	default:
		return false
	}
}

func bookingWasAccepted(booking models.Booking) bool {
	if booking.AcceptedAt != nil {
		return true
	}

	switch strings.ToLower(strings.TrimSpace(booking.Status)) {
	case "accepted", "in progress", "completed", "under review":
		return true
	default:
		return false
	}
}

func bookingWasCompleted(booking models.Booking) bool {
	if booking.CompletedAt != nil {
		return true
	}

	return strings.EqualFold(strings.TrimSpace(booking.Status), "Completed")
}

func bookingStartTime(booking models.Booking) *time.Time {
	if booking.StartedAt != nil {
		return booking.StartedAt
	}

	if strings.EqualFold(strings.TrimSpace(booking.Status), "In Progress") {
		return &booking.UpdatedAt
	}

	return nil
}

func bookingStartedOnTime(booking models.Booking, startedAt time.Time) bool {
	scheduledAt, err := services.ParseScheduledTime(booking.PreferredDate, booking.PreferredTime)
	if err != nil {
		return false
	}

	// Allow a small grace window for check-in variance and device latency.
	return !startedAt.After(scheduledAt.Add(15 * time.Minute))
}

func readFloatSummaryValue(summary map[string]any, key string) float64 {
	value, ok := summary[key]
	if !ok {
		return 0
	}

	switch typed := value.(type) {
	case float64:
		return typed
	case float32:
		return float64(typed)
	case int:
		return float64(typed)
	case int64:
		return float64(typed)
	default:
		parsed, _ := strconv.ParseFloat(normalizeScalarString(value), 64)
		return parsed
	}
}

func readIntSummaryValue(summary map[string]any, key string) int {
	value, ok := summary[key]
	if !ok {
		return 0
	}

	switch typed := value.(type) {
	case int:
		return typed
	case int64:
		return int(typed)
	case float64:
		return int(typed)
	default:
		parsed, _ := strconv.Atoi(normalizeScalarString(value))
		return parsed
	}
}

func safeRatio(numerator int, denominator int) float64 {
	if denominator <= 0 {
		return 0
	}

	return float64(numerator) / float64(denominator)
}

func weightedPerformanceScore(
	responseRate float64,
	hasResponse bool,
	completionRate float64,
	hasCompletion bool,
	customerSatisfaction float64,
	hasSatisfaction bool,
	onTimeArrival float64,
	hasOnTime bool,
) float64 {
	totalWeight := 0.0
	score := 0.0

	if hasResponse {
		totalWeight += 0.25
		score += responseRate * 100 * 0.25
	}
	if hasCompletion {
		totalWeight += 0.25
		score += completionRate * 100 * 0.25
	}
	if hasSatisfaction {
		totalWeight += 0.35
		score += (customerSatisfaction / 5) * 100 * 0.35
	}
	if hasOnTime {
		totalWeight += 0.15
		score += onTimeArrival * 100 * 0.15
	}

	if totalWeight == 0 {
		return 0
	}

	return score / totalWeight
}

func performanceLabel(score float64) string {
	switch {
	case score >= 90:
		return "Excellent"
	case score >= 80:
		return "Very Good"
	case score >= 70:
		return "Good"
	case score >= 60:
		return "Fair"
	default:
		return "Needs Improvement"
	}
}

func roundToWholePercent(value float64) int {
	return int(clampFloat(value, 0, 1)*100 + 0.5)
}

func clampFloat(value float64, min float64, max float64) float64 {
	if value < min {
		return min
	}
	if value > max {
		return max
	}
	return value
}

func normalizedCancellationReason(booking models.Booking) string {
	return strings.ToLower(strings.TrimSpace(booking.CancellationReason))
}

func normalizeScalarString(value any) string {
	switch typed := value.(type) {
	case string:
		return strings.TrimSpace(strings.ReplaceAll(typed, ",", ""))
	default:
		return ""
	}
}

func getBookingsByID(bookingIDs []uint) map[uint]models.Booking {
	out := map[uint]models.Booking{}
	if len(bookingIDs) == 0 {
		return out
	}

	var bookings []models.Booking
	if err := config.DB.Where("id IN ?", bookingIDs).Find(&bookings).Error; err != nil {
		return out
	}

	for _, booking := range bookings {
		out[booking.ID] = booking
	}

	return out
}

func parseReviewRatingFilter(raw string) (int, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0, false
	}

	rating, err := strconv.Atoi(raw)
	if err != nil || rating < 1 || rating > 5 {
		return 0, false
	}

	return rating, true
}

func tagsContain(tags []string, needle string) bool {
	for _, tag := range tags {
		if strings.EqualFold(strings.TrimSpace(tag), needle) {
			return true
		}
	}
	return false
}

func TradespersonReviewsByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	// Path format: /api/tradespeople/{id}/reviews
	// parts: [api, tradespeople, {id}, reviews]
	if len(parts) < 4 || parts[3] != "reviews" {
		writeError(w, http.StatusBadRequest, "invalid request")
		return
	}

	tradespersonID, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid tradesperson ID")
		return
	}

	var reviews []models.BookingReview
	if err := config.DB.Where("tradesperson_id = ?", uint(tradespersonID)).Find(&reviews).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load reviews")
		return
	}

	// Default to recent reviews, limit to 10
	sort.Slice(reviews, func(i, j int) bool {
		return reviews[i].CreatedAt.After(reviews[j].CreatedAt)
	})

	if len(reviews) > 10 {
		reviews = reviews[:10]
	}

	bookingIDs := make([]uint, 0, len(reviews))
	homeownerIDs := make([]uint, 0, len(reviews))
	for _, review := range reviews {
		bookingIDs = append(bookingIDs, review.BookingID)
		homeownerIDs = append(homeownerIDs, review.HomeownerID)
	}

	bookingsByID := getBookingsByID(bookingIDs)
	homeownersByID := getHomeownerProfilesByUserID(homeownerIDs)
	photosByUserID := getProfilePhotosByUserID(homeownerIDs)

	rows := make([]map[string]any, 0, len(reviews))
	for _, review := range reviews {
		_ = bookingsByID[review.BookingID]
		homeowner := homeownersByID[review.HomeownerID]
		photo := photosByUserID[review.HomeownerID]

		homeownerName := strings.TrimSpace(homeowner.FirstName + " " + homeowner.LastName)
		if homeownerName == "" {
			homeownerName = "Homeowner"
		}

		rows = append(rows, map[string]any{
			"id":                          review.ID,
			"homeowner_name":              homeownerName,
			"homeowner_avatar":            initialsFromName(homeowner.FirstName, homeowner.LastName, "HO"),
			"homeowner_profile_image_url": buildPublicUploadURL(r, photo.FilePath),
			"rating":                      review.Rating,
			"comment":                     review.Comment,
			"created_at":                  review.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"reviews": rows,
	})
}
