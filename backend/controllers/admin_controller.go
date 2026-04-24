package controllers

import (
	"encoding/json"
	"net/http"
	"sort"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
)

type reviewVerificationRequest struct {
	VerificationID uint   `json:"verification_id"`
	Status         string `json:"status"`
}

type activityEntry struct {
	ID        string
	Type      string
	Title     string
	Sub       string
	CreatedAt any
}

// ListDocuments handles GET /api/admin/documents
// Optional query param: ?status=pending|approved|rejected|archived  (omit to return all)
func ListDocuments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	status := strings.TrimSpace(r.URL.Query().Get("status"))

	var docs []models.VerificationDocument
	query := config.DB.Preload("User")
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if err := query.Order("created_at desc").Find(&docs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list documents")
		return
	}

	homeownersByID := getHomeownerProfilesByUserID(extractUserIDsFromDocuments(docs))
	tradespeopleByID := getTradespersonProfilesByUserID(extractUserIDsFromDocuments(docs))

	rows := make([]map[string]any, 0, len(docs))
	for _, d := range docs {
		role := strings.ToLower(strings.TrimSpace(d.User.Role))
		firstName := ""
		lastName := ""
		if role == "homeowner" {
			profile := homeownersByID[d.UserID]
			firstName = profile.FirstName
			lastName = profile.LastName
		} else if role == "tradesperson" {
			profile := tradespeopleByID[d.UserID]
			firstName = profile.FirstName
			lastName = profile.LastName
		}

		rows = append(rows, map[string]any{
			"id":             d.ID,
			"user_id":        d.UserID,
			"user_email":     d.User.Email,
			"user_name":      buildUserDisplayName(d.User, firstName, lastName),
			"document_group": d.DocumentGroup,
			"document_type":  d.DocumentType,
			"original_name":  d.OriginalName,
			"file_path":      d.FilePath,
			"document_url":   buildPublicUploadURL(r, d.FilePath),
			"mime_type":      d.MimeType,
			"file_size":      d.FileSize,
			"status":         d.Status,
			"created_at":     d.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"documents": rows})
}

// HandleDocument routes PATCH /api/admin/documents/{id}/approve|reject
func HandleDocument(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

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

	status := "approved"
	if action == "reject" {
		status = "rejected"
	}

	if err := applyVerificationStatus(uint(docID), status); err != nil {
		handleVerificationMutationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":     "document " + status,
		"document_id": docID,
		"status":      status,
	})
}

// ListTradespeople handles GET /api/admin/tradespeople
// Optional query param: ?status=pending|approved|rejected|suspended
func ListTradespeople(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	statusFilter := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("status")))

	var profiles []models.TradespersonProfile
	if err := config.DB.Preload("User").Order("created_at desc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	userIDs := make([]uint, 0, len(profiles))
	for _, p := range profiles {
		userIDs = append(userIDs, p.UserID)
	}

	licenseDocs := getLatestDocumentsByGroup("license", userIDs)
	governmentDocs := getLatestDocumentsByGroup("government_id", userIDs)
	jobCounts := getBookingCountsByColumn("tradesperson_id", userIDs)

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		status := strings.ToLower(strings.TrimSpace(p.VerificationStatus))
		if !p.User.IsActive {
			status = "suspended"
		}
		if statusFilter != "" && status != statusFilter {
			continue
		}

		licenseDoc, hasLicense := licenseDocs[p.UserID]
		governmentDoc, hasGovernment := governmentDocs[p.UserID]
		fullName := buildUserDisplayName(p.User, p.FirstName, p.LastName)

		row := map[string]any{
			"id":                  p.UserID,
			"user_id":             p.UserID,
			"profile_id":          p.ID,
			"user_email":          p.User.Email,
			"email":               p.User.Email,
			"full_name":           fullName,
			"first_name":          p.FirstName,
			"last_name":           p.LastName,
			"phone":               p.Phone,
			"trade_category":      p.TradeCategory,
			"years_experience":    p.YearsExperience,
			"service_barangay":    p.ServiceBarangay,
			"bio":                 p.Bio,
			"verification_status": p.VerificationStatus,
			"status":              status,
			"is_active":           p.User.IsActive,
			"jobs_count":          jobCounts[p.UserID],
			"created_at":          p.User.CreatedAt,
		}

		if hasLicense {
			row["license"] = licenseDoc.DocumentType
			row["license_document_url"] = buildPublicUploadURL(r, licenseDoc.FilePath)
			row["credential_url"] = buildPublicUploadURL(r, licenseDoc.FilePath)
		}
		if hasGovernment {
			row["government_id_document_url"] = buildPublicUploadURL(r, governmentDoc.FilePath)
		}

		rows = append(rows, row)
	}

	writeJSON(w, http.StatusOK, map[string]any{"tradespeople": rows})
}

func ListHomeowners(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	statusFilter := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("status")))

	var profiles []models.HomeownerProfile
	if err := config.DB.Preload("User").Order("created_at desc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list homeowners")
		return
	}

	userIDs := make([]uint, 0, len(profiles))
	for _, p := range profiles {
		userIDs = append(userIDs, p.UserID)
	}

	idDocs := getLatestDocumentsByGroup("government_id", userIDs)
	jobCounts := getBookingCountsByColumn("homeowner_id", userIDs)

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		status := "active"
		if !p.User.IsActive {
			status = "inactive"
		}
		if statusFilter != "" && status != statusFilter {
			continue
		}

		fullName := buildUserDisplayName(p.User, p.FirstName, p.LastName)
		row := map[string]any{
			"id":         p.UserID,
			"user_id":    p.UserID,
			"profile_id": p.ID,
			"user_email": p.User.Email,
			"email":      p.User.Email,
			"full_name":  fullName,
			"first_name": p.FirstName,
			"last_name":  p.LastName,
			"barangay":   p.Barangay,
			"location":   p.Barangay,
			"status":     status,
			"is_active":  p.User.IsActive,
			"jobs_count": jobCounts[p.UserID],
			"created_at": p.User.CreatedAt,
		}

		if idDoc, ok := idDocs[p.UserID]; ok {
			row["id_status"] = idDoc.Status
			row["id_number"] = idDoc.DocumentType
			row["id_document_url"] = buildPublicUploadURL(r, idDoc.FilePath)
		} else {
			row["id_status"] = "pending"
		}

		rows = append(rows, row)
	}

	writeJSON(w, http.StatusOK, map[string]any{"homeowners": rows})
}

func ListVerifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var homeowners []models.HomeownerProfile
	if err := config.DB.Preload("User").Order("created_at desc").Find(&homeowners).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load homeowner verifications")
		return
	}

	var tradespeople []models.TradespersonProfile
	if err := config.DB.Preload("User").Order("created_at desc").Find(&tradespeople).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load tradesperson verifications")
		return
	}

	homeownerIDs := make([]uint, 0, len(homeowners))
	for _, p := range homeowners {
		homeownerIDs = append(homeownerIDs, p.UserID)
	}
	tradespersonIDs := make([]uint, 0, len(tradespeople))
	for _, p := range tradespeople {
		tradespersonIDs = append(tradespersonIDs, p.UserID)
	}

	homeownerDocs := getLatestDocumentsByGroup("government_id", homeownerIDs)
	tradespersonDocs := getLatestDocumentsByGroup("license", tradespersonIDs)

	rows := make([]map[string]any, 0, len(homeownerDocs)+len(tradespersonDocs))
	for _, profile := range homeowners {
		doc, ok := homeownerDocs[profile.UserID]
		if !ok {
			continue
		}

		rows = append(rows, map[string]any{
			"id":           doc.ID,
			"user_id":      profile.UserID,
			"user_name":    buildUserDisplayName(profile.User, profile.FirstName, profile.LastName),
			"type":         "homeowner_id",
			"status":       doc.Status,
			"document_url": buildPublicUploadURL(r, doc.FilePath),
			"created_at":   doc.CreatedAt,
		})
	}

	for _, profile := range tradespeople {
		doc, ok := tradespersonDocs[profile.UserID]
		if !ok {
			continue
		}

		rows = append(rows, map[string]any{
			"id":           doc.ID,
			"user_id":      profile.UserID,
			"user_name":    buildUserDisplayName(profile.User, profile.FirstName, profile.LastName),
			"type":         "tradesperson_license",
			"status":       doc.Status,
			"document_url": buildPublicUploadURL(r, doc.FilePath),
			"created_at":   doc.CreatedAt,
		})
	}

	sort.Slice(rows, func(i, j int) bool {
		left, _ := rows[i]["created_at"].(interface{ UnixNano() int64 })
		right, _ := rows[j]["created_at"].(interface{ UnixNano() int64 })
		if left == nil || right == nil {
			return false
		}
		return left.UnixNano() > right.UnixNano()
	})

	writeJSON(w, http.StatusOK, map[string]any{"verifications": rows})
}

func ReviewVerification(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req reviewVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	status := strings.ToLower(strings.TrimSpace(req.Status))
	if req.VerificationID == 0 || (status != "approved" && status != "rejected") {
		writeError(w, http.StatusBadRequest, "verification_id and a valid status are required")
		return
	}

	if err := applyVerificationStatus(req.VerificationID, status); err != nil {
		handleVerificationMutationError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "verification updated successfully",
		"status":  status,
	})
}

func VerificationByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 3 || parts[0] != "api" || parts[1] != "verifications" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	verificationID, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil || verificationID == 0 {
		writeError(w, http.StatusBadRequest, "invalid verification id")
		return
	}

	switch r.Method {
	case http.MethodDelete:
		if err := archiveVerification(uint(verificationID)); err != nil {
			handleVerificationMutationError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"message": "verification archived",
			"status":  "archived",
		})
	case http.MethodPatch:
		if err := restoreVerification(uint(verificationID)); err != nil {
			handleVerificationMutationError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"message": "verification restored",
			"status":  "approved",
		})
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func AdminTradespersonByIDRouter(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 || parts[0] != "api" || parts[1] != "admin" || parts[2] != "tradespeople" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || userID == 0 {
		writeError(w, http.StatusBadRequest, "invalid tradesperson id")
		return
	}

	switch parts[4] {
	case "revoke":
		if err := setUserActiveState(uint(userID), false, "tradesperson"); err != nil {
			handleUserStateError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"message": "tradesperson suspended"})
	case "restore":
		if err := setUserActiveState(uint(userID), true, "tradesperson"); err != nil {
			handleUserStateError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"message": "tradesperson restored"})
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
}

func AdminHomeownerByIDRouter(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 || parts[0] != "api" || parts[1] != "admin" || parts[2] != "homeowners" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	userID, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || userID == 0 {
		writeError(w, http.StatusBadRequest, "invalid homeowner id")
		return
	}

	switch parts[4] {
	case "revoke":
		if err := setUserActiveState(uint(userID), false, "homeowner"); err != nil {
			handleUserStateError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"message": "homeowner revoked"})
	case "restore":
		if err := setUserActiveState(uint(userID), true, "homeowner"); err != nil {
			handleUserStateError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"message": "homeowner restored"})
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
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

	entries := make([]activityEntry, 0, 24)

	var users []models.User
	_ = config.DB.Order("created_at desc").Limit(8).Find(&users).Error
	for _, user := range users {
		entries = append(entries, activityEntry{
			ID:        "user-" + strconv.FormatUint(uint64(user.ID), 10),
			Type:      "user_registered",
			Title:     buildUserDisplayName(user, "", "") + " joined FIXIT",
			Sub:       "Registered as " + strings.Title(user.Role),
			CreatedAt: user.CreatedAt,
		})
	}

	var docs []models.VerificationDocument
	_ = config.DB.Preload("User").Order("created_at desc").Limit(8).Find(&docs).Error
	homeownerProfiles := getHomeownerProfilesByUserID(extractUserIDsFromDocuments(docs))
	tradespersonProfiles := getTradespersonProfilesByUserID(extractUserIDsFromDocuments(docs))
	for _, doc := range docs {
		firstName := ""
		lastName := ""
		if doc.User.Role == "homeowner" {
			profile := homeownerProfiles[doc.UserID]
			firstName = profile.FirstName
			lastName = profile.LastName
		} else if doc.User.Role == "tradesperson" {
			profile := tradespersonProfiles[doc.UserID]
			firstName = profile.FirstName
			lastName = profile.LastName
		}

		title := buildUserDisplayName(doc.User, firstName, lastName) + " submitted verification"
		if doc.Status == "approved" {
			title = buildUserDisplayName(doc.User, firstName, lastName) + " verification approved"
		}
		if doc.Status == "rejected" {
			title = buildUserDisplayName(doc.User, firstName, lastName) + " verification rejected"
		}
		if doc.Status == "archived" {
			title = buildUserDisplayName(doc.User, firstName, lastName) + " verification archived"
		}

		entryType := "verification_submitted"
		switch doc.Status {
		case "approved":
			entryType = "verification_approved"
		case "rejected":
			entryType = "verification_rejected"
		case "archived":
			entryType = "verification_archived"
		}

		entries = append(entries, activityEntry{
			ID:        "verification-" + strconv.FormatUint(uint64(doc.ID), 10),
			Type:      entryType,
			Title:     title,
			Sub:       strings.ReplaceAll(strings.Title(strings.ReplaceAll(doc.DocumentGroup, "_", " ")), "Id", "ID"),
			CreatedAt: doc.CreatedAt,
		})
	}

	var issues []models.BookingIssue
	_ = config.DB.Order("created_at desc").Limit(8).Find(&issues).Error
	for _, issue := range issues {
		entries = append(entries, activityEntry{
			ID:        "issue-" + strconv.FormatUint(uint64(issue.ID), 10),
			Type:      "booking_under_review",
			Title:     "New report filed",
			Sub:       issue.Category,
			CreatedAt: issue.CreatedAt,
		})
	}

	var bookings []models.Booking
	_ = config.DB.Order("updated_at desc").Limit(8).Find(&bookings).Error
	for _, booking := range bookings {
		entryType := "booking_updated"
		switch strings.ToLower(strings.TrimSpace(booking.Status)) {
		case "completed":
			entryType = "booking_completed"
		case "cancelled", "canceled":
			entryType = "booking_cancelled"
		case "under review":
			entryType = "booking_under_review"
		}

		entries = append(entries, activityEntry{
			ID:        "booking-" + strconv.FormatUint(uint64(booking.ID), 10),
			Type:      entryType,
			Title:     "Booking #" + strconv.FormatUint(uint64(booking.ID), 10) + " updated",
			Sub:       booking.Status,
			CreatedAt: booking.UpdatedAt,
		})
	}

	sort.Slice(entries, func(i, j int) bool {
		left, lok := entries[i].CreatedAt.(interface{ UnixNano() int64 })
		right, rok := entries[j].CreatedAt.(interface{ UnixNano() int64 })
		if !lok || !rok {
			return false
		}
		return left.UnixNano() > right.UnixNano()
	})

	if len(entries) > limit {
		entries = entries[:limit]
	}

	rows := make([]map[string]any, 0, len(entries))
	for _, entry := range entries {
		rows = append(rows, map[string]any{
			"id":         entry.ID,
			"type":       entry.Type,
			"title":      entry.Title,
			"sub":        entry.Sub,
			"created_at": entry.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"activity": rows})
}

func ListAdminReviews(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var reviews []models.BookingReview
	if err := config.DB.Order("created_at desc").Find(&reviews).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list reviews")
		return
	}

	bookingIDs := make([]uint, 0, len(reviews))
	homeownerIDs := make([]uint, 0, len(reviews))
	tradespersonIDs := make([]uint, 0, len(reviews))
	for _, review := range reviews {
		bookingIDs = append(bookingIDs, review.BookingID)
		homeownerIDs = append(homeownerIDs, review.HomeownerID)
		tradespersonIDs = append(tradespersonIDs, review.TradespersonID)
	}

	bookingsByID := getBookingsByID(bookingIDs)
	homeownersByID := getHomeownerProfilesByUserID(homeownerIDs)
	tradespeopleByID := getTradespersonProfilesByUserID(tradespersonIDs)
	usersByID := getUsersByID(uniqueUintSlice(append(homeownerIDs, tradespersonIDs...)))

	rows := make([]map[string]any, 0, len(reviews))
	for _, review := range reviews {
		booking := bookingsByID[review.BookingID]
		homeowner := homeownersByID[review.HomeownerID]
		tradesperson := tradespeopleByID[review.TradespersonID]
		tradespersonUser := usersByID[review.TradespersonID]

		jobType := strings.TrimSpace(booking.Specialization)
		if jobType == "" {
			jobType = booking.TradeCategory
		}

		rows = append(rows, map[string]any{
			"id":               review.ID,
			"tradesman_id":     review.TradespersonID,
			"tradesman_email":  tradespersonUser.Email,
			"tradesman_name":   buildUserDisplayName(tradespersonUser, tradesperson.FirstName, tradesperson.LastName),
			"reviewer_name":    buildUserDisplayName(usersByID[review.HomeownerID], homeowner.FirstName, homeowner.LastName),
			"reviewer_role":    "Homeowner",
			"rating":           review.Rating,
			"job_type":         jobType,
			"comment":          review.Comment,
			"submitted_at":     review.CreatedAt,
			"verified_booking": true,
			"booking_id":       review.BookingID,
			"trade_category":   booking.TradeCategory,
			"specialization":   booking.Specialization,
			"tradesperson_id":  review.TradespersonID,
			"homeowner_id":     review.HomeownerID,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"reviews": rows})
}

func ListAdminReports(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var issues []models.BookingIssue
	if err := config.DB.Order("created_at desc").Find(&issues).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list reports")
		return
	}

	bookingIDs := make([]uint, 0, len(issues))
	homeownerIDs := make([]uint, 0, len(issues))
	for _, issue := range issues {
		bookingIDs = append(bookingIDs, issue.BookingID)
		homeownerIDs = append(homeownerIDs, issue.HomeownerID)
	}

	bookingsByID := getBookingsByID(bookingIDs)
	tradespersonIDs := make([]uint, 0, len(issues))
	for _, issue := range issues {
		if booking, ok := bookingsByID[issue.BookingID]; ok {
			tradespersonIDs = append(tradespersonIDs, booking.TradespersonID)
		}
	}

	homeownersByID := getHomeownerProfilesByUserID(homeownerIDs)
	tradespeopleByID := getTradespersonProfilesByUserID(tradespersonIDs)
	usersByID := getUsersByID(uniqueUintSlice(append(homeownerIDs, tradespersonIDs...)))

	rows := make([]map[string]any, 0, len(issues))
	for _, issue := range issues {
		booking, ok := bookingsByID[issue.BookingID]
		if !ok {
			continue
		}

		reporterProfile := homeownersByID[issue.HomeownerID]
		targetProfile := tradespeopleByID[booking.TradespersonID]
		targetUser := usersByID[booking.TradespersonID]

		status := "Open"
		switch strings.ToLower(strings.TrimSpace(issue.Status)) {
		case "resolved":
			status = "Resolved"
		case "under review":
			status = "Reviewing"
		}

		rows = append(rows, map[string]any{
			"id":            issue.ID,
			"target_type":   "Tradesman",
			"target_name":   buildUserDisplayName(targetUser, targetProfile.FirstName, targetProfile.LastName),
			"target_email":  targetUser.Email,
			"reporter_name": buildUserDisplayName(usersByID[issue.HomeownerID], reporterProfile.FirstName, reporterProfile.LastName),
			"reporter_role": "Homeowner",
			"reason":        issue.Category,
			"details":       issue.Details,
			"status":        status,
			"submitted_at":  issue.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"reports": rows})
}

func applyVerificationStatus(verificationID uint, status string) error {
	var doc models.VerificationDocument
	if err := config.DB.Preload("User").First(&doc, verificationID).Error; err != nil {
		return err
	}

	if doc.Status != "pending" {
		return errConflict("verification has already been reviewed")
	}

	if strings.EqualFold(doc.User.Role, "tradesperson") {
		if err := config.DB.Model(&models.VerificationDocument{}).
			Where("user_id = ? AND status <> ?", doc.UserID, "archived").
			Update("status", status).Error; err != nil {
			return err
		}
		syncTradespersonStatus(doc.UserID)
		return nil
	}

	if err := config.DB.Model(&doc).Update("status", status).Error; err != nil {
		return err
	}

	return nil
}

func archiveVerification(verificationID uint) error {
	var doc models.VerificationDocument
	if err := config.DB.Preload("User").First(&doc, verificationID).Error; err != nil {
		return err
	}

	if doc.Status == "archived" {
		return errConflict("verification is already archived")
	}

	if strings.EqualFold(doc.User.Role, "tradesperson") {
		if err := config.DB.Model(&models.VerificationDocument{}).
			Where("user_id = ? AND status <> ?", doc.UserID, "archived").
			Update("status", "archived").Error; err != nil {
			return err
		}
		syncTradespersonStatus(doc.UserID)
		return nil
	}

	return config.DB.Model(&doc).Update("status", "archived").Error
}

func restoreVerification(verificationID uint) error {
	var doc models.VerificationDocument
	if err := config.DB.Preload("User").First(&doc, verificationID).Error; err != nil {
		return err
	}

	if doc.Status != "archived" {
		return errConflict("only archived verifications can be restored")
	}

	if strings.EqualFold(doc.User.Role, "tradesperson") {
		if err := config.DB.Model(&models.VerificationDocument{}).
			Where("user_id = ? AND status = ?", doc.UserID, "archived").
			Update("status", "approved").Error; err != nil {
			return err
		}
		syncTradespersonStatus(doc.UserID)
		return nil
	}

	return config.DB.Model(&doc).Update("status", "approved").Error
}

func setUserActiveState(userID uint, isActive bool, expectedRole string) error {
	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		return err
	}

	if expectedRole != "" && user.Role != expectedRole {
		return errConflict("user does not match the requested role")
	}

	return config.DB.Model(&user).Update("is_active", isActive).Error
}

func getLatestDocumentsByGroup(group string, userIDs []uint) map[uint]models.VerificationDocument {
	out := map[uint]models.VerificationDocument{}
	if len(userIDs) == 0 {
		return out
	}

	var docs []models.VerificationDocument
	if err := config.DB.
		Where("user_id IN ? AND document_group = ?", userIDs, group).
		Order("created_at desc").
		Find(&docs).Error; err != nil {
		return out
	}

	for _, doc := range docs {
		if _, exists := out[doc.UserID]; exists {
			continue
		}
		out[doc.UserID] = doc
	}

	return out
}

func getBookingCountsByColumn(column string, userIDs []uint) map[uint]int64 {
	out := map[uint]int64{}
	if len(userIDs) == 0 {
		return out
	}

	type row struct {
		UserID uint
		Count  int64
	}

	var rows []row
	if err := config.DB.
		Model(&models.Booking{}).
		Select(column+" AS user_id, COUNT(*) AS count").
		Where(column+" IN ?", userIDs).
		Group(column).
		Scan(&rows).Error; err != nil {
		return out
	}

	for _, row := range rows {
		out[row.UserID] = row.Count
	}

	return out
}

func getUsersByID(userIDs []uint) map[uint]models.User {
	out := map[uint]models.User{}
	if len(userIDs) == 0 {
		return out
	}

	var users []models.User
	if err := config.DB.Where("id IN ?", userIDs).Find(&users).Error; err != nil {
		return out
	}

	for _, user := range users {
		out[user.ID] = user
	}

	return out
}

func extractUserIDsFromDocuments(docs []models.VerificationDocument) []uint {
	userIDs := make([]uint, 0, len(docs))
	for _, doc := range docs {
		userIDs = append(userIDs, doc.UserID)
	}
	return uniqueUintSlice(userIDs)
}

func uniqueUintSlice(values []uint) []uint {
	if len(values) == 0 {
		return values
	}

	seen := map[uint]struct{}{}
	out := make([]uint, 0, len(values))
	for _, value := range values {
		if _, exists := seen[value]; exists {
			continue
		}
		seen[value] = struct{}{}
		out = append(out, value)
	}

	return out
}

func buildUserDisplayName(user models.User, firstName string, lastName string) string {
	if fullName := buildUserFullName(user, firstName, lastName); fullName != "" {
		return fullName
	}

	if user.Email == "" {
		return "User"
	}

	local := strings.TrimSpace(strings.Split(user.Email, "@")[0])
	if local == "" {
		return "User"
	}

	parts := strings.FieldsFunc(local, func(r rune) bool {
		return r == '.' || r == '_' || r == '-'
	})
	if len(parts) == 0 {
		return strings.Title(local)
	}

	for i := range parts {
		parts[i] = strings.Title(parts[i])
	}

	return strings.Join(parts, " ")
}

type conflictError struct {
	message string
}

func (e conflictError) Error() string {
	return e.message
}

func errConflict(message string) error {
	return conflictError{message: message}
}

func handleVerificationMutationError(w http.ResponseWriter, err error) {
	if err == nil {
		return
	}

	switch err.(type) {
	case conflictError:
		writeError(w, http.StatusConflict, err.Error())
	default:
		if strings.Contains(strings.ToLower(err.Error()), "record not found") {
			writeError(w, http.StatusNotFound, "verification not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to update verification")
	}
}

func handleUserStateError(w http.ResponseWriter, err error) {
	if err == nil {
		return
	}

	switch err.(type) {
	case conflictError:
		writeError(w, http.StatusConflict, err.Error())
	default:
		if strings.Contains(strings.ToLower(err.Error()), "record not found") {
			writeError(w, http.StatusNotFound, "user not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to update user")
	}
}

// syncTradespersonStatus re-evaluates the tradesperson profile's verification_status
// based on the current state of all their documents:
//   - Any doc "rejected"  -> profile becomes "rejected"
//   - All docs "approved" -> profile becomes "approved"
//   - Otherwise           -> stays "pending"
func syncTradespersonStatus(userID uint) {
	var docs []models.VerificationDocument
	if err := config.DB.Where("user_id = ?", userID).Find(&docs).Error; err != nil || len(docs) == 0 {
		return
	}

	allApproved := true
	for _, doc := range docs {
		if doc.Status == "rejected" {
			config.DB.Model(&models.TradespersonProfile{}).
				Where("user_id = ?", userID).
				Update("verification_status", "rejected")
			return
		}
		if doc.Status != "approved" {
			allApproved = false
		}
	}

	nextStatus := "pending"
	if allApproved {
		nextStatus = "approved"
	}

	config.DB.Model(&models.TradespersonProfile{}).
		Where("user_id = ?", userID).
		Update("verification_status", nextStatus)
}
