package controllers

import (
	"net/http"
	"sort"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
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
