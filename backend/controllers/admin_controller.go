package controllers

import (
	"encoding/json"
	"net/http"
<<<<<<< HEAD
	"sort"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
=======
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
)

// ListDocuments handles GET /api/admin/documents
// Optional query param: ?status=pending|approved|rejected  (omit to return all)
func ListDocuments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	status := r.URL.Query().Get("status")

	var docs []models.VerificationDocument
	query := config.DB.Preload("User")
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if err := query.Order("created_at asc").Find(&docs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list documents")
		return
	}

	rows := make([]map[string]any, 0, len(docs))
	for _, d := range docs {
		rows = append(rows, map[string]any{
			"id":             d.ID,
			"user_id":        d.UserID,
			"user_email":     d.User.Email,
			"document_group": d.DocumentGroup,
			"document_type":  d.DocumentType,
			"original_name":  d.OriginalName,
			"file_path":      d.FilePath,
			"mime_type":      d.MimeType,
			"file_size":      d.FileSize,
			"status":         d.Status,
			"created_at":     d.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"documents": rows})
}

// HandleDocument routes PATCH /api/admin/documents/{id}/approve|reject
// Path must be exactly: /api/admin/documents/{id}/approve  OR  .../reject
func HandleDocument(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	// Split path into segments: ["api","admin","documents","{id}","approve|reject"]
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	docID, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid document id")
		return
	}

	action := parts[4]
	if action != "approve" && action != "reject" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	// Optional JSON body — only used for reject reason
	var body struct {
		Reason string `json:"reason"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	var doc models.VerificationDocument
	if err := config.DB.First(&doc, docID).Error; err != nil {
		writeError(w, http.StatusNotFound, "document not found")
		return
	}

	if doc.Status != "pending" {
		writeError(w, http.StatusConflict, "document has already been reviewed")
		return
	}

	newStatus := "approved"
	if action == "reject" {
		newStatus = "rejected"
	}

	if err := config.DB.Model(&doc).Update("status", newStatus).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update document status")
		return
	}

	// Keep tradesperson profile verification_status in sync
	syncTradespersonStatus(doc.UserID)

	writeJSON(w, http.StatusOK, map[string]any{
		"message":     "document " + newStatus,
		"document_id": doc.ID,
		"status":      newStatus,
	})
}

// ListTradespeople handles GET /api/admin/tradespeople
// Optional query param: ?status=pending|approved|rejected  (omit to return all)
func ListTradespeople(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	status := r.URL.Query().Get("status")

	var profiles []models.TradespersonProfile
	query := config.DB.Preload("User")
	if status != "" {
		query = query.Where("verification_status = ?", status)
	}
	if err := query.Order("created_at asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
<<<<<<< HEAD
		docs := findVerificationDocumentsForUser(p.UserID)
		licenseDoc := findDocumentByGroup(docs, "license")
		govDoc := findDocumentByGroup(docs, "government_id")
		status := deriveTradespersonAdminStatus(p.User.IsActive, p.VerificationStatus)
		rows = append(rows, map[string]any{
			"id":                         p.ID,
			"user_id":                    p.UserID,
			"user_email":                 p.User.Email,
			"full_name":                  adminUserDisplayName(p.User, p.FirstName, p.LastName),
			"first_name":                 p.FirstName,
			"last_name":                  p.LastName,
			"phone":                      p.Phone,
			"trade_category":             p.TradeCategory,
			"years_experience":           p.YearsExperience,
			"service_barangay":           p.ServiceBarangay,
			"bio":                        p.Bio,
			"license":                    documentReference("LIC", licenseDoc, p.UserID),
			"license_document_url":       buildPublicFileURL(r, documentFilePath(licenseDoc)),
			"government_id_document_url": buildPublicFileURL(r, documentFilePath(govDoc)),
			"status":                     status,
			"verification_status":        p.VerificationStatus,
			"created_at":                 p.CreatedAt,
=======
		rows = append(rows, map[string]any{
			"id":                  p.ID,
			"user_id":             p.UserID,
			"user_email":          p.User.Email,
			"first_name":          p.FirstName,
			"last_name":           p.LastName,
			"phone":               p.Phone,
			"trade_category":      p.TradeCategory,
			"years_experience":    p.YearsExperience,
			"service_barangay":    p.ServiceBarangay,
			"bio":                 p.Bio,
			"verification_status": p.VerificationStatus,
			"created_at":          p.CreatedAt,
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"tradespeople": rows})
}

<<<<<<< HEAD
func ListHomeowners(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var profiles []models.HomeownerProfile
	if err := config.DB.Preload("User").Order("created_at asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list homeowners")
		return
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		docs := findVerificationDocumentsForUser(p.UserID)
		idDoc := findDocumentByGroup(docs, "government_id")
		idStatus := "pending"
		if idDoc != nil && idDoc.Status != "" {
			idStatus = idDoc.Status
		}

		rows = append(rows, map[string]any{
			"id":              p.ID,
			"user_id":         p.UserID,
			"user_email":      p.User.Email,
			"full_name":       adminUserDisplayName(p.User, p.FirstName, p.LastName),
			"first_name":      p.FirstName,
			"last_name":       p.LastName,
			"phone":           p.Phone,
			"barangay":        p.Barangay,
			"bio":             p.Bio,
			"gender":          p.Gender,
			"id_number":       documentReference("HO-ID", idDoc, p.UserID),
			"id_status":       idStatus,
			"id_document_url": buildPublicFileURL(r, documentFilePath(idDoc)),
			"status":          deriveHomeownerAdminStatus(p.User.IsActive, idStatus),
			"created_at":      p.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"homeowners": rows})
}

func HandleTradespersonAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	id, action, ok := parseAdminActionPath(r.URL.Path, "/api/admin/tradespeople/")
	if !ok {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	now := time.Now()
	switch action {
	case "revoke":
		if err := config.DB.Transaction(func(tx *gorm.DB) error {
			if err := tx.Model(&models.TradespersonProfile{}).
				Where("id = ?", id).
				Updates(map[string]any{"verification_status": "rejected", "updated_at": now}).Error; err != nil {
				return err
			}

			var profile models.TradespersonProfile
			if err := tx.First(&profile, id).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.VerificationDocument{}).
				Where("user_id = ? AND status <> ?", profile.UserID, "archived").
				Updates(map[string]any{"status": "rejected", "updated_at": now}).Error; err != nil {
				return err
			}

			return tx.Model(&models.User{}).
				Where("id = ?", profile.UserID).
				Updates(map[string]any{"is_active": false, "updated_at": now}).Error
		}); err != nil {
			writeError(w, http.StatusInternalServerError, "failed to revoke tradesperson")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"message": "tradesperson suspended"})
	case "restore":
		if err := config.DB.Transaction(func(tx *gorm.DB) error {
			var profile models.TradespersonProfile
			if err := tx.First(&profile, id).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.TradespersonProfile{}).
				Where("id = ?", id).
				Updates(map[string]any{"verification_status": "approved", "updated_at": now}).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.VerificationDocument{}).
				Where("user_id = ?", profile.UserID).
				Updates(map[string]any{"status": "approved", "updated_at": now}).Error; err != nil {
				return err
			}

			return tx.Model(&models.User{}).
				Where("id = ?", profile.UserID).
				Updates(map[string]any{"is_active": true, "updated_at": now}).Error
		}); err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore tradesperson")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"message": "tradesperson restored"})
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
}

func HandleHomeownerAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	id, action, ok := parseAdminActionPath(r.URL.Path, "/api/admin/homeowners/")
	if !ok {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	var profile models.HomeownerProfile
	if err := config.DB.First(&profile, id).Error; err != nil {
		writeError(w, http.StatusNotFound, "homeowner not found")
		return
	}

	active := action == "restore"
	if action != "revoke" && action != "restore" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	if err := config.DB.Model(&models.User{}).
		Where("id = ?", profile.UserID).
		Updates(map[string]any{"is_active": active, "updated_at": time.Now()}).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update homeowner")
		return
	}

	message := "homeowner revoked"
	if active {
		message = "homeowner restored"
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": message})
}

func ListActivity(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	limit := 6
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 50 {
			limit = parsed
		}
	}

	var docs []models.VerificationDocument
	_ = config.DB.Preload("User").Order("updated_at desc").Limit(limit * 2).Find(&docs).Error

	var users []models.User
	_ = config.DB.Order("created_at desc").Limit(limit).Find(&users).Error

	var bookings []models.Booking
	_ = config.DB.
		Preload("HomeownerUser").
		Preload("TradespersonUser").
		Order("updated_at desc").
		Limit(limit * 3).
		Find(&bookings).Error

	entries := make([]map[string]any, 0, limit*2)
	for _, doc := range docs {
		title, sub, entryType := formatActivityFromDocument(doc)
		entries = append(entries, map[string]any{
			"id":         "doc-" + strconv.FormatUint(uint64(doc.ID), 10),
			"title":      title,
			"sub":        sub,
			"type":       entryType,
			"created_at": doc.UpdatedAt,
		})
	}

	for _, user := range users {
		entries = append(entries, map[string]any{
			"id":         "user-" + strconv.FormatUint(uint64(user.ID), 10),
			"title":      "New " + titleCase(user.Role) + " registration",
			"sub":        adminUserDisplayName(user) + " joined the platform.",
			"type":       "user_registered",
			"created_at": user.CreatedAt,
		})
	}

	for _, booking := range bookings {
		title, sub, entryType, eventAt := formatActivityFromBooking(booking)
		entries = append(entries, map[string]any{
			"id":         "booking-" + strconv.FormatUint(uint64(booking.ID), 10),
			"title":      title,
			"sub":        sub,
			"type":       entryType,
			"created_at": eventAt,
		})
	}

	sort.Slice(entries, func(i, j int) bool {
		left, _ := entries[i]["created_at"].(time.Time)
		right, _ := entries[j]["created_at"].(time.Time)
		return right.Before(left)
	})

	if len(entries) > limit {
		entries = entries[:limit]
	}

	writeJSON(w, http.StatusOK, map[string]any{"activity": entries})
}

=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
// syncTradespersonStatus re-evaluates the tradesperson profile's verification_status
// based on the current state of all their documents:
//   - Any doc "rejected"  → profile becomes "rejected"
//   - All docs "approved" → profile becomes "approved"
//   - Otherwise           → stays "pending"
func syncTradespersonStatus(userID uint) {
	var docs []models.VerificationDocument
	if err := config.DB.Where("user_id = ?", userID).Find(&docs).Error; err != nil || len(docs) == 0 {
		return
	}

	allApproved := true
	for _, d := range docs {
		if d.Status == "rejected" {
			config.DB.Model(&models.TradespersonProfile{}).
				Where("user_id = ?", userID).
				Update("verification_status", "rejected")
			return
		}
		if d.Status != "approved" {
			allApproved = false
		}
	}

	if allApproved {
		config.DB.Model(&models.TradespersonProfile{}).
			Where("user_id = ?", userID).
			Update("verification_status", "approved")
	}
}
<<<<<<< HEAD

func adminVerificationType(role, documentGroup string) (string, bool) {
	switch {
	case role == "homeowner" && documentGroup == "government_id":
		return "homeowner_id", true
	case role == "tradesperson" && documentGroup == "license":
		return "tradesperson_license", true
	default:
		return "", false
	}
}

func adminUserDisplayName(user models.User, nameParts ...string) string {
	var firstName, lastName string
	if len(nameParts) > 0 {
		firstName = nameParts[0]
	}
	if len(nameParts) > 1 {
		lastName = nameParts[1]
	}
	if firstName == "" && lastName == "" {
		firstName, lastName, _, _, _ = getUserProfileDetails(user.ID, user.Role)
	}
	return buildDisplayName(user.FullName, firstName, lastName, user.Email)
}

func findVerificationDocumentsForUser(userID uint) []models.VerificationDocument {
	var docs []models.VerificationDocument
	_ = config.DB.Where("user_id = ?", userID).Order("created_at asc").Find(&docs).Error
	return docs
}

func findDocumentByGroup(docs []models.VerificationDocument, group string) *models.VerificationDocument {
	for i := range docs {
		if docs[i].DocumentGroup == group {
			return &docs[i]
		}
	}
	return nil
}

func documentFilePath(doc *models.VerificationDocument) string {
	if doc == nil {
		return ""
	}
	return doc.FilePath
}

func documentReference(prefix string, doc *models.VerificationDocument, fallbackUserID uint) string {
	if doc != nil && doc.ID > 0 {
		return prefix + "-" + strconv.FormatUint(uint64(doc.ID), 10)
	}
	return prefix + "-" + strconv.FormatUint(uint64(fallbackUserID), 10)
}

func deriveTradespersonAdminStatus(isActive bool, verificationStatus string) string {
	switch {
	case !isActive:
		return "suspended"
	case strings.EqualFold(verificationStatus, "approved"):
		return "verified"
	case strings.EqualFold(verificationStatus, "rejected"):
		return "suspended"
	default:
		return "pending"
	}
}

func deriveHomeownerAdminStatus(isActive bool, idStatus string) string {
	switch {
	case !isActive:
		return "inactive"
	case strings.EqualFold(idStatus, "pending"):
		return "pending"
	case strings.EqualFold(idStatus, "approved"):
		return "active"
	default:
		return "inactive"
	}
}

func parseAdminActionPath(path, prefix string) (uint, string, bool) {
	trimmed := strings.TrimPrefix(path, prefix)
	parts := strings.Split(strings.Trim(trimmed, "/"), "/")
	if len(parts) != 2 {
		return 0, "", false
	}

	id, err := strconv.ParseUint(parts[0], 10, 64)
	if err != nil {
		return 0, "", false
	}

	return uint(id), parts[1], true
}

func formatActivityFromDocument(doc models.VerificationDocument) (string, string, string) {
	displayName := adminUserDisplayName(doc.User)
	docLabel := "document"
	if doc.DocumentGroup == "license" {
		docLabel = "license"
	} else if doc.DocumentGroup == "government_id" {
		docLabel = "government ID"
	}

	switch doc.Status {
	case "approved":
		return "Verification approved", displayName + "'s " + docLabel + " was approved.", "verification_approved"
	case "rejected":
		return "Verification rejected", displayName + "'s " + docLabel + " was rejected.", "verification_rejected"
	case "archived":
		return "Verification archived", displayName + "'s " + docLabel + " was archived.", "verification_archived"
	default:
		if doc.UpdatedAt.After(doc.CreatedAt.Add(2 * time.Second)) {
			return "Verification reset", displayName + "'s verification was returned to pending.", "tradesperson_reverify"
		}
		return "Verification submitted", displayName + " uploaded a " + docLabel + ".", "verification_submitted"
	}
}

func formatActivityFromBooking(booking models.Booking) (string, string, string, time.Time) {
	tradespersonName := adminUserDisplayName(booking.TradespersonUser)
	homeownerName := adminUserDisplayName(booking.HomeownerUser)

	service := strings.TrimSpace(booking.Specialization)
	if service == "" {
		service = strings.TrimSpace(booking.Trade)
	}
	if service == "" {
		service = "service request"
	}

	status := strings.ToLower(strings.TrimSpace(booking.Status))
	eventAt := booking.UpdatedAt
	if eventAt.IsZero() {
		eventAt = booking.CreatedAt
	}

	switch status {
	case "accepted":
		return "Booking accepted",
			tradespersonName + " accepted " + homeownerName + "'s booking for " + service + ".",
			"booking_accepted",
			eventAt
	case "in progress", "in_progress", "in-progress":
		if booking.StartedAt != nil && !booking.StartedAt.IsZero() {
			eventAt = *booking.StartedAt
		}
		return "Job started",
			tradespersonName + " started a job for " + homeownerName + ".",
			"booking_started",
			eventAt
	case "completed":
		if booking.CompletedAt != nil && !booking.CompletedAt.IsZero() {
			eventAt = *booking.CompletedAt
		}
		return "Job completed",
			tradespersonName + " completed a job for " + homeownerName + ".",
			"booking_completed",
			eventAt
	case "cancelled", "canceled":
		return "Booking cancelled",
			"A booking between " + homeownerName + " and " + tradespersonName + " was cancelled.",
			"booking_cancelled",
			eventAt
	case "under review", "under_review", "under-review", "disputed":
		return "Booking under review",
			homeownerName + " reported an issue for a booking with " + tradespersonName + ".",
			"booking_under_review",
			eventAt
	default:
		return "New booking request",
			homeownerName + " requested " + service + " from " + tradespersonName + ".",
			"booking_created",
			booking.CreatedAt
	}
}

func titleCase(value string) string {
	if value == "" {
		return ""
	}
	return strings.ToUpper(value[:1]) + strings.ToLower(value[1:])
}
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
