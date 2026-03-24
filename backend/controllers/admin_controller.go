package controllers

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
)

func documentFileExists(path string) bool {
	if strings.TrimSpace(path) == "" {
		return false
	}
	if _, err := os.Stat(path); err != nil {
		return false
	}
	return true
}

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
	if status == "" {
		query = query.Where("status != ?", "archived")
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

// HandleDocument routes:
// PATCH /api/admin/documents/{id}/approve|reject
// GET   /api/admin/documents/{id}/file
func HandleDocument(w http.ResponseWriter, r *http.Request) {
	// Split path into segments: ["api","admin","documents","{id}","approve|reject|file"]
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
	switch action {
	case "file":
		if r.Method != http.MethodGet {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}

		var doc models.VerificationDocument
		if err := config.DB.First(&doc, docID).Error; err != nil {
			writeError(w, http.StatusNotFound, "document not found")
			return
		}
		if !documentFileExists(doc.FilePath) {
			writeError(w, http.StatusNotFound, "document file missing")
			return
		}

		http.ServeFile(w, r, doc.FilePath)
		return

	case "approve", "reject":
		if r.Method != http.MethodPatch {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
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
		return

	default:
		writeError(w, http.StatusNotFound, "not found")
		return
	}
}

// HandleTradesperson routes:
// PATCH /api/admin/tradespeople/{id}/revoke
// PATCH /api/admin/tradespeople/{id}/restore
func HandleTradesperson(w http.ResponseWriter, r *http.Request) {
	// Split path into segments: ["api","admin","tradespeople","{id}","revoke"]
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	id, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || id == 0 {
		writeError(w, http.StatusBadRequest, "invalid tradesperson id")
		return
	}

	action := parts[4]
	if action != "revoke" && action != "restore" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var profile models.TradespersonProfile
	if err := config.DB.First(&profile, id).Error; err != nil {
		// Fallback: allow passing user_id instead of profile id.
		if err := config.DB.Where("user_id = ?", id).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "tradesperson not found")
			return
		}
	}

	fullName := strings.TrimSpace(profile.FirstName + " " + profile.LastName)
	if fullName == "" {
		fullName = fmt.Sprintf("User #%d", profile.UserID)
	}

	switch action {
	case "revoke":
		if err := config.DB.Model(&profile).Update("verification_status", "pending").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to set tradesperson to pending")
			return
		}

		if err := config.DB.Model(&models.VerificationDocument{}).
			Where("user_id = ? AND document_group = ?", profile.UserID, "license").
			Update("status", "pending").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to reset tradesperson documents")
			return
		}

		_ = logActivity(
			"Re-verification requested",
			fmt.Sprintf("%s · Status reset to pending", fullName),
			"tradesperson_reverify",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":             "tradesperson set to pending",
			"tradesperson_id":     profile.ID,
			"user_id":             profile.UserID,
			"verification_status": "pending",
		})
	case "restore":
		if err := config.DB.Model(&profile).Update("verification_status", "approved").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore tradesperson")
			return
		}

		if err := config.DB.Model(&models.VerificationDocument{}).
			Where("user_id = ? AND document_group = ?", profile.UserID, "license").
			Update("status", "approved").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore tradesperson documents")
			return
		}

		_ = logActivity(
			"Tradesperson restored",
			fmt.Sprintf("%s · Status set to approved", fullName),
			"tradesperson_restored",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":             "tradesperson restored",
			"tradesperson_id":     profile.ID,
			"user_id":             profile.UserID,
			"verification_status": "approved",
		})
	}
}

// HandleHomeowner routes:
// PATCH /api/admin/homeowners/{id}/revoke
// PATCH /api/admin/homeowners/{id}/restore
func HandleHomeowner(w http.ResponseWriter, r *http.Request) {
	// Split path into segments: ["api","admin","homeowners","{id}","revoke"]
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	id, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || id == 0 {
		writeError(w, http.StatusBadRequest, "invalid homeowner id")
		return
	}

	action := parts[4]
	if action != "revoke" && action != "restore" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var profile models.HomeownerProfile
	if err := config.DB.First(&profile, id).Error; err != nil {
		// Fallback: allow passing user_id instead of profile id.
		if err := config.DB.Where("user_id = ?", id).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "homeowner not found")
			return
		}
	}

	fullName := strings.TrimSpace(profile.FirstName + " " + profile.LastName)
	if fullName == "" {
		fullName = fmt.Sprintf("User #%d", profile.UserID)
	}
	switch action {
	case "revoke":
		if err := config.DB.Model(&models.User{}).
			Where("id = ?", profile.UserID).
			Update("is_active", false).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to revoke homeowner")
			return
		}

		_ = logActivity(
			"Homeowner revoked",
			fmt.Sprintf("%s · Account set to inactive", fullName),
			"homeowner_revoked",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":        "homeowner revoked",
			"homeowner_id":   profile.ID,
			"user_id":        profile.UserID,
			"account_status": "inactive",
		})
	case "restore":
		if err := config.DB.Model(&models.User{}).
			Where("id = ?", profile.UserID).
			Update("is_active", true).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore homeowner")
			return
		}

		_ = logActivity(
			"Homeowner restored",
			fmt.Sprintf("%s · Account set to active", fullName),
			"homeowner_restored",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":        "homeowner restored",
			"homeowner_id":   profile.ID,
			"user_id":        profile.UserID,
			"account_status": "active",
		})
	}
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
	// Use an inner join to exclude orphaned profiles when users are deleted.
	query := config.DB.Joins("User").Preload("User")
	if status != "" {
		query = query.Where("verification_status = ?", status)
	}
	if err := query.Order("created_at asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	userIDs := make([]uint, 0, len(profiles))
	for _, p := range profiles {
		userIDs = append(userIDs, p.UserID)
	}

	licenseDocMap := map[uint]models.VerificationDocument{}
	governmentDocMap := map[uint]models.VerificationDocument{}
	if len(userIDs) > 0 {
		var docs []models.VerificationDocument
		if err := config.DB.
			Where("user_id IN ? AND LOWER(document_group) IN ?", userIDs, []string{"license", "government_id"}).
			Order("created_at desc").
			Find(&docs).Error; err == nil {
			for _, d := range docs {
				if !documentFileExists(d.FilePath) {
					continue
				}
				switch strings.ToLower(d.DocumentGroup) {
				case "license":
					if _, exists := licenseDocMap[d.UserID]; !exists {
						licenseDocMap[d.UserID] = d
					}
				case "government_id":
					if _, exists := governmentDocMap[d.UserID]; !exists {
						governmentDocMap[d.UserID] = d
					}
				}
			}
		}
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		row := map[string]any{
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
		}

		if doc, ok := licenseDocMap[p.UserID]; ok {
			row["license_document_url"] = fmt.Sprintf("/api/admin/documents/%d/file", doc.ID)
			row["license_document_type"] = doc.DocumentType
		}
		if doc, ok := governmentDocMap[p.UserID]; ok {
			row["government_id_document_url"] = fmt.Sprintf("/api/admin/documents/%d/file", doc.ID)
			row["government_id_document_type"] = doc.DocumentType
		}

		rows = append(rows, row)
	}

	writeJSON(w, http.StatusOK, map[string]any{"tradespeople": rows})
}

// ListHomeowners handles GET /api/admin/homeowners
func ListHomeowners(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var profiles []models.HomeownerProfile
	// Use an inner join to exclude orphaned profiles when users are deleted.
	query := config.DB.Joins("User").Preload("User")
	if err := query.Order("created_at asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list homeowners")
		return
	}

	userIDs := make([]uint, 0, len(profiles))
	for _, p := range profiles {
		userIDs = append(userIDs, p.UserID)
	}

	docMap := map[uint]models.VerificationDocument{}
	if len(userIDs) > 0 {
		var docs []models.VerificationDocument
		groups := []string{"government_id", "homeowner_id"}
		if err := config.DB.
			Where("user_id IN ? AND LOWER(document_group) IN ?", userIDs, groups).
			Order("created_at desc").
			Find(&docs).Error; err == nil {
			for _, d := range docs {
				if !documentFileExists(d.FilePath) {
					continue
				}
				if _, exists := docMap[d.UserID]; !exists {
					docMap[d.UserID] = d
				}
			}
		}
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		fullName := strings.TrimSpace(p.FirstName + " " + p.LastName)
		status := "active"
		if !p.User.IsActive {
			status = "inactive"
		}
		row := map[string]any{
			"id":         p.ID,
			"user_id":    p.UserID,
			"email":      p.User.Email,
			"full_name":  fullName,
			"barangay":   p.Barangay,
			"created_at": p.CreatedAt,
			"status":     status,
		}

		idStatus := strings.TrimSpace(p.StatusID)
		if doc, ok := docMap[p.UserID]; ok {
			if idStatus == "" {
				idStatus = doc.Status
			}
			row["id_document_url"] = fmt.Sprintf("/api/admin/documents/%d/file", doc.ID)
			row["id_document_type"] = doc.DocumentType
		}
		if idStatus != "" {
			row["id_status"] = idStatus
		}

		rows = append(rows, row)
	}

	writeJSON(w, http.StatusOK, map[string]any{"homeowners": rows})
}

// ListVerifications handles GET /api/verifications
// Optional query param: ?status=pending|approved|rejected  (omit to return all)
func ListVerifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	status := r.URL.Query().Get("status")

	var docs []models.VerificationDocument
	// Be tolerant to legacy/alternate group labels and casing.
	groups := []string{"government_id", "license", "homeowner_id", "tradesperson_license"}
	query := config.DB.Preload("User").
		Where("LOWER(document_group) IN ?", groups)
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if err := query.Order("created_at asc").Find(&docs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list verifications")
		return
	}

	rows := make([]map[string]any, 0, len(docs))
	for _, d := range docs {
		var vType string
		switch strings.ToLower(d.DocumentGroup) {
		case "license", "tradesperson_license":
			vType = "tradesperson_license"
		case "government_id", "homeowner_id":
			// Only homeowner government IDs belong in verification queue.
			if d.User.Role != "" && d.User.Role != "homeowner" {
				continue
			}
			vType = "homeowner_id"
		default:
			continue
		}

		rows = append(rows, map[string]any{
			"id":           d.ID,
			"user_id":      d.UserID,
			"type":         vType,
			"status":       d.Status,
			"document_url": func() string {
				if !documentFileExists(d.FilePath) {
					return ""
				}
				return fmt.Sprintf("/api/admin/documents/%d/file", d.ID)
			}(),
			"created_at":   d.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"verifications": rows})
}

// ReviewVerification handles POST /api/verifications/review
func ReviewVerification(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var body struct {
		VerificationID uint   `json:"verification_id"`
		Status         string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if body.VerificationID == 0 {
		writeError(w, http.StatusBadRequest, "verification_id is required")
		return
	}

	if body.Status != "approved" && body.Status != "rejected" {
		writeError(w, http.StatusBadRequest, "status must be approved or rejected")
		return
	}

	var doc models.VerificationDocument
	if err := config.DB.First(&doc, body.VerificationID).Error; err != nil {
		writeError(w, http.StatusNotFound, "verification not found")
		return
	}

	if doc.Status != "pending" {
		writeError(w, http.StatusConflict, "verification has already been reviewed")
		return
	}

	if err := config.DB.Model(&doc).Update("status", body.Status).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update verification")
		return
	}

	switch strings.ToLower(doc.DocumentGroup) {
	case "government_id", "homeowner_id":
		if err := updateHomeownerIDStatus(doc.UserID, body.Status); err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update homeowner id status")
			return
		}
	}

	syncTradespersonStatus(doc.UserID)

	_ = logActivity(
		fmt.Sprintf("Verification %s", body.Status),
		fmt.Sprintf("User #%d · %s", doc.UserID, verificationTypeLabel(doc)),
		"verification_"+body.Status,
	)

	writeJSON(w, http.StatusOK, map[string]any{
		"message":         "verification " + body.Status,
		"verification_id": doc.ID,
		"status":          body.Status,
	})
}

func ensureHomeownerProfile(userID uint) error {
	var existing models.HomeownerProfile
	if err := config.DB.Where("user_id = ?", userID).First(&existing).Error; err == nil {
		return nil
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	// Best-effort: derive from tradesperson profile if present.
	var tp models.TradespersonProfile
	profile := models.HomeownerProfile{
		UserID:    userID,
		FirstName: "Unknown",
		LastName:  "User",
		Phone:     "N/A",
		Barangay:  "Unknown",
	}
	if err := config.DB.Where("user_id = ?", userID).First(&tp).Error; err == nil {
		if tp.FirstName != "" {
			profile.FirstName = tp.FirstName
		}
		if tp.LastName != "" {
			profile.LastName = tp.LastName
		}
		if tp.Phone != "" {
			profile.Phone = tp.Phone
		}
		if tp.ServiceBarangay != "" {
			profile.Barangay = tp.ServiceBarangay
		}
	}

	return config.DB.Create(&profile).Error
}

func updateHomeownerIDStatus(userID uint, status string) error {
	if err := ensureHomeownerProfile(userID); err != nil {
		return err
	}
	return config.DB.
		Model(&models.HomeownerProfile{}).
		Where("user_id = ?", userID).
		Update("status_id", status).Error
}

// HandleVerification routes:
// DELETE /api/verifications/{id}
// PATCH  /api/verifications/{id}
func HandleVerification(w http.ResponseWriter, r *http.Request) {
	// Split path into segments: ["api","verifications","{id}"]
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 3 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	id, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil || id == 0 {
		writeError(w, http.StatusBadRequest, "invalid verification id")
		return
	}

	var doc models.VerificationDocument
	if err := config.DB.First(&doc, id).Error; err != nil {
		writeError(w, http.StatusNotFound, "verification not found")
		return
	}

	switch r.Method {
	case http.MethodDelete:
		if err := config.DB.Model(&doc).Update("status", "archived").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to archive verification")
			return
		}

		if strings.EqualFold(doc.DocumentGroup, "government_id") || strings.EqualFold(doc.DocumentGroup, "homeowner_id") {
			if err := updateHomeownerIDStatus(doc.UserID, "archived"); err != nil {
				writeError(w, http.StatusInternalServerError, "failed to update homeowner id status")
				return
			}
		}

		_ = logActivity(
			"Verification archived",
			fmt.Sprintf("User #%d · %s", doc.UserID, verificationTypeLabel(doc)),
			"verification_archived",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":         "verification archived",
			"verification_id": id,
			"status":          "archived",
		})
		return

	case http.MethodPatch:
		if doc.Status != "archived" {
			writeError(w, http.StatusConflict, "only archived verifications can be restored")
			return
		}

		if err := config.DB.Model(&doc).Update("status", "approved").Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore verification")
			return
		}

		if strings.EqualFold(doc.DocumentGroup, "government_id") || strings.EqualFold(doc.DocumentGroup, "homeowner_id") {
			if err := updateHomeownerIDStatus(doc.UserID, "approved"); err != nil {
				writeError(w, http.StatusInternalServerError, "failed to update homeowner id status")
				return
			}
		}

		syncTradespersonStatus(doc.UserID)

		_ = logActivity(
			"Verification restored",
			fmt.Sprintf("User #%d · %s", doc.UserID, verificationTypeLabel(doc)),
			"verification_restored",
		)

		writeJSON(w, http.StatusOK, map[string]any{
			"message":         "verification restored",
			"verification_id": id,
			"status":          "approved",
		})
		return

	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
}

// syncTradespersonStatus re-evaluates the tradesperson profile's verification_status
// based on their LICENSE documents:
//   - Any license doc "rejected"  → profile becomes "rejected"
//   - Any license doc "approved"  → profile becomes "approved"
//   - Otherwise                   → stays "pending"
func syncTradespersonStatus(userID uint) {
	var docs []models.VerificationDocument
	if err := config.DB.
		Where("user_id = ? AND document_group = ? AND status != ?", userID, "license", "archived").
		Find(&docs).Error; err != nil || len(docs) == 0 {
		return
	}

	hasApproved := false
	for _, d := range docs {
		if d.Status == "rejected" {
			config.DB.Model(&models.TradespersonProfile{}).
				Where("user_id = ?", userID).
				Update("verification_status", "rejected")
			return
		}
		if d.Status == "approved" {
			hasApproved = true
		}
	}

	if hasApproved {
		config.DB.Model(&models.TradespersonProfile{}).
			Where("user_id = ?", userID).
			Update("verification_status", "approved")
	}
}

// ListActivity handles GET /api/admin/activity?limit=6
func ListActivity(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	limit := 6
	if v := r.URL.Query().Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			if n > 50 {
				limit = 50
			} else {
				limit = n
			}
		}
	}

	var items []models.ActivityLog
	if err := config.DB.Order("created_at desc").Limit(limit).Find(&items).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list activity")
		return
	}

	rows := make([]map[string]any, 0, len(items))
	for _, a := range items {
		rows = append(rows, map[string]any{
			"id":         a.ID,
			"title":      a.Title,
			"sub":        a.Sub,
			"type":       a.Type,
			"created_at": a.CreatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"activity": rows})
}

func logActivity(title, sub, activityType string) error {
	return config.DB.Create(&models.ActivityLog{
		Title: title,
		Sub:   sub,
		Type:  activityType,
	}).Error
}

func verificationTypeLabel(doc models.VerificationDocument) string {
	switch strings.ToLower(doc.DocumentGroup) {
	case "license", "tradesperson_license":
		return "Tradesperson License"
	case "government_id", "homeowner_id":
		return "Homeowner ID"
	default:
		return "Verification"
	}
}
