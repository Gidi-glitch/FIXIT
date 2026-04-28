package services

import (
	"fmt"
	"log"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"
)

const (
	// SameDayAcceptanceWindow is the acceptance window for bookings scheduled on the same day
	SameDayAcceptanceWindow = 1 * time.Hour
	// FutureDayAcceptanceWindow is the acceptance window for bookings scheduled for a future date
	FutureDayAcceptanceWindow = 24 * time.Hour
	// PreScheduledCutoff is the minimum time before scheduled service time when booking must expire
	PreScheduledCutoff = 40 * time.Minute
	// SchedulerInterval is how often the expiration check runs
	SchedulerInterval = 1 * time.Minute
)

// ComputeExpirationTime calculates the expiration time for a booking based on:
// 1. Acceptance window (1 hour for same-day, 24 hours for future-day bookings)
// 2. Pre-scheduled cutoff (must expire 40 minutes before scheduled time)
// Returns: expiration_time = MIN(created_at + acceptance_window, schedule_time - 40 minutes)
func ComputeExpirationTime(createdAt time.Time, preferredDate string, preferredTime string) (time.Time, error) {
	// Parse the scheduled time from date and time strings
	scheduledTime, err := parseScheduledTime(preferredDate, preferredTime)
	if err != nil {
		return time.Time{}, fmt.Errorf("failed to parse scheduled time: %w", err)
	}

	// Determine acceptance window based on whether booking is same-day or future-day
	acceptanceWindow := getAcceptanceWindow(createdAt, scheduledTime)

	// Calculate two potential expiration times
	acceptanceWindowExpiry := createdAt.Add(acceptanceWindow)
	preScheduledCutoffExpiry := scheduledTime.Add(-PreScheduledCutoff)

	// Return the earlier of the two
	if acceptanceWindowExpiry.Before(preScheduledCutoffExpiry) {
		return acceptanceWindowExpiry, nil
	}
	return preScheduledCutoffExpiry, nil
}

// ParseScheduledTime combines the preferred date and time strings into a single time.Time
// Expects date in YYYY-MM-DD format (also accepts Today/Tomorrow or month names)
// and time in 24-hour or 12-hour formats (HH:MM, HH:MM:SS, 3:04 PM).
func ParseScheduledTime(dateStr, timeStr string) (time.Time, error) {
	dateStr = strings.TrimSpace(dateStr)
	timeStr = strings.TrimSpace(timeStr)
	if dateStr == "" || timeStr == "" {
		return time.Time{}, fmt.Errorf("date or time is empty")
	}

	dateOnly, err := parseDateOnly(dateStr)
	if err != nil {
		return time.Time{}, err
	}

	hour, minute, second, nsec, err := parseTimeOnly(timeStr)
	if err != nil {
		return time.Time{}, err
	}

	return time.Date(
		dateOnly.Year(),
		dateOnly.Month(),
		dateOnly.Day(),
		hour,
		minute,
		second,
		nsec,
		time.Local,
	), nil
}

func parseDateOnly(dateStr string) (time.Time, error) {
	trimmed := strings.TrimSpace(dateStr)
	if trimmed == "" {
		return time.Time{}, fmt.Errorf("date is empty")
	}

	now := time.Now().In(time.Local)
	dateLower := strings.ToLower(trimmed)
	if dateLower == "today" {
		return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local), nil
	}
	if dateLower == "tomorrow" {
		tomorrow := now.AddDate(0, 0, 1)
		return time.Date(tomorrow.Year(), tomorrow.Month(), tomorrow.Day(), 0, 0, 0, 0, time.Local), nil
	}

	// Full dates with year
	dateLayouts := []string{
		"2006-01-02",
		"2006-1-2",
		"2006/01/02",
		"2006/1/2",
		"01/02/2006",
		"1/2/2006",
		"02/01/2006",
		"2/1/2006",
		"Jan 2 2006",
		"January 2 2006",
		"Jan 2, 2006",
		"January 2, 2006",
	}
	for _, layout := range dateLayouts {
		if parsed, err := time.ParseInLocation(layout, trimmed, time.Local); err == nil {
			return time.Date(parsed.Year(), parsed.Month(), parsed.Day(), 0, 0, 0, 0, time.Local), nil
		}
	}

	// Dates without year (assume current year)
	dateLayoutsNoYear := []string{
		"Jan 2",
		"January 2",
		"Jan 02",
		"January 02",
		"02 Jan",
		"02 January",
	}
	for _, layout := range dateLayoutsNoYear {
		if parsed, err := time.ParseInLocation(layout, trimmed, time.Local); err == nil {
			return time.Date(now.Year(), parsed.Month(), parsed.Day(), 0, 0, 0, 0, time.Local), nil
		}
	}

	return time.Time{}, fmt.Errorf("invalid date format")
}

func parseTimeOnly(timeStr string) (int, int, int, int, error) {
	trimmed := strings.TrimSpace(timeStr)
	if trimmed == "" {
		return 0, 0, 0, 0, fmt.Errorf("time is empty")
	}

	layouts := []string{
		"15:04:05",
		"15:04",
		"15:04:05.000",
		"15:04:05.000Z07:00",
		"15:04:05Z07:00",
		"15:04Z07:00",
		"3:04 PM",
		"03:04 PM",
		"3 PM",
		"03 PM",
		"3:04PM",
		"03:04PM",
		"3PM",
		"03PM",
	}

	candidates := []string{trimmed, strings.ToUpper(trimmed)}
	var parseErr error
	for _, candidate := range candidates {
		for _, layout := range layouts {
			if parsed, err := time.Parse(layout, candidate); err == nil {
				return parsed.Hour(), parsed.Minute(), parsed.Second(), parsed.Nanosecond(), nil
			} else {
				parseErr = err
			}
		}
	}

	return 0, 0, 0, 0, parseErr
}

// parseScheduledTime combines the preferred date and time strings into a single time.Time
// Expects date in YYYY-MM-DD format and time in HH:MM format
func parseScheduledTime(dateStr, timeStr string) (time.Time, error) {
	return ParseScheduledTime(dateStr, timeStr)
}

// getAcceptanceWindow determines if the booking is same-day or future-day
// and returns the appropriate acceptance window
func getAcceptanceWindow(createdAt time.Time, scheduledTime time.Time) time.Duration {
	// Compare calendar dates in local time
	createdDate := createdAt.In(time.Local)
	scheduledDate := scheduledTime.In(time.Local)

	// Same calendar day
	if createdDate.Year() == scheduledDate.Year() &&
		createdDate.YearDay() == scheduledDate.YearDay() {
		return SameDayAcceptanceWindow
	}

	// Future day (or past day, but that should be validated elsewhere)
	return FutureDayAcceptanceWindow
}

// ValidateBookingSchedule checks if a booking can be created
// Returns error if scheduled_time - current_time <= 40 minutes
func ValidateBookingSchedule(scheduledTime time.Time) error {
	now := time.Now()
	timeUntilSchedule := scheduledTime.Sub(now)

	if timeUntilSchedule <= PreScheduledCutoff {
		return fmt.Errorf("booking must be scheduled at least 40 minutes in advance (got %v)", timeUntilSchedule.Round(time.Minute))
	}

	return nil
}

// CheckAndExpirePendingBookings scans for pending bookings where expiration_time <= now
// and auto-cancels them with appropriate notifications
func CheckAndExpirePendingBookings() error {
	now := time.Now()

	var expiredBookings []models.Booking
	if err := config.DB.Where("status = ? AND expiration_time <= ?", "Pending", now).
		Find(&expiredBookings).Error; err != nil {
		return fmt.Errorf("failed to query expired bookings: %w", err)
	}

	if len(expiredBookings) == 0 {
		return nil
	}

	log.Printf("🕒 Found %d expired bookings to process", len(expiredBookings))

	for _, booking := range expiredBookings {
		if err := expireBooking(&booking); err != nil {
			log.Printf("❌ Failed to expire booking %d: %v", booking.ID, err)
			continue
		}
		log.Printf("✅ Expired booking %d (homeowner=%d, tradesperson=%d)",
			booking.ID, booking.HomeownerID, booking.TradespersonID)
	}

	return nil
}

// expireBooking cancels a single booking and sends notifications to both parties
// Uses conditional update to prevent race conditions with acceptance
func expireBooking(booking *models.Booking) error {
	tx := config.DB.Begin()
	defer tx.Rollback()

	// Lock the booking row and verify it's still pending (concurrency safety)
	if err := tx.Set("gorm:query_option", "FOR UPDATE").
		First(&models.Booking{}, booking.ID).Error; err != nil {
		return fmt.Errorf("failed to lock booking: %w", err)
	}

	// Conditional update: only expire if still pending
	result := tx.Model(booking).Where("status = ?", "Pending").Updates(map[string]any{
		"status":              "Cancelled",
		"cancelled_at":        time.Now(),
		"cancellation_reason": "expired_unaccepted",
	})

	if result.RowsAffected == 0 {
		// Booking was already accepted/changed by another transaction
		log.Printf("⚠️  Booking %d status changed during expiration, skipping", booking.ID)
		return nil
	}

	if result.Error != nil {
		return fmt.Errorf("failed to update booking: %w", result.Error)
	}

	// Create notification for homeowner
	homeownerNotification := models.Notification{
		UserID:  booking.HomeownerID,
		Title:   "Booking Expired",
		Message: fmt.Sprintf("Your booking request for %s expired — the tradesperson didn't accept within the time limit. Browse other available tradespeople.", booking.TradeCategory),
		Type:    "booking_expired",
	}
	if err := tx.Create(&homeownerNotification).Error; err != nil {
		return fmt.Errorf("failed to create homeowner notification: %w", err)
	}

	// Create notification for tradesperson
	var tradespersonProfile models.TradespersonProfile
	if err := tx.Where("user_id = ?", booking.TradespersonID).First(&tradespersonProfile).Error; err != nil {
		return fmt.Errorf("failed to load tradesperson profile: %w", err)
	}

	tradespersonNotification := models.Notification{
		UserID:  booking.TradespersonID,
		Title:   "Booking Expired",
		Message: fmt.Sprintf("You failed to accept the %s job request within the time limit. Repeated expirations may affect your visibility.", booking.TradeCategory),
		Type:    "booking_expired",
	}
	if err := tx.Create(&tradespersonNotification).Error; err != nil {
		return fmt.Errorf("failed to create tradesperson notification: %w", err)
	}

	// Commit the transaction
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// StartExpirationScheduler runs the expiration check every 1 minute
func StartExpirationScheduler(stopChan <-chan struct{}) {
	ticker := time.NewTicker(SchedulerInterval)
	defer ticker.Stop()

	log.Printf("⏰ Booking expiration scheduler started (checking every %v)", SchedulerInterval)

	for {
		select {
		case <-ticker.C:
			if err := CheckAndExpirePendingBookings(); err != nil {
				log.Printf("❌ Expiration check failed: %v", err)
			}
		case <-stopChan:
			log.Println("🛑 Booking expiration scheduler stopped")
			return
		}
	}
}
