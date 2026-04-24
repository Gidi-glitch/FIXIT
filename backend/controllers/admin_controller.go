package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
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
	if err := query.Order("created_at asc, id asc").Find(&docs).Error; err != nil {
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
	if err := query.Order("created_at asc, id asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list tradespeople")
		return
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		var bookingsCount int64
		_ = config.DB.Model(&models.Booking{}).Where("tradesperson_id = ?", p.UserID).Count(&bookingsCount).Error
		licenseDoc, _ := latestVerificationDocument(p.UserID, "license")
		governmentDoc, _ := latestVerificationDocument(p.UserID, "government_id")
		status := "pending"
		if !p.User.IsActive {
			status = "suspended"
		} else if strings.EqualFold(p.VerificationStatus, "approved") {
			status = "approved"
		} else if strings.EqualFold(p.VerificationStatus, "rejected") {
			status = "rejected"
		}

		rows = append(rows, map[string]any{
			"id":                  p.UserID,
			"profile_id":          p.ID,
			"user_id":             p.UserID,
			"user_email":          p.User.Email,
			"email":               p.User.Email,
			"full_name":           strings.TrimSpace(p.FirstName + " " + p.LastName),
			"first_name":          p.FirstName,
			"last_name":           p.LastName,
			"phone":               p.Phone,
			"trade_category":      p.TradeCategory,
			"category":            p.TradeCategory,
			"license":             fmt.Sprintf("TRD-%d", p.ID),
			"credential_url":      buildPublicFileURL(r, licenseDoc.FilePath),
			"government_id_document_url": buildPublicFileURL(r, governmentDoc.FilePath),
			"years_experience":    p.YearsExperience,
			"service_barangay":    p.ServiceBarangay,
			"bio":                 p.Bio,
			"status":              status,
			"verification_status": p.VerificationStatus,
			"jobs_count":          bookingsCount,
			"created_at":          p.CreatedAt,
		})
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
	if err := config.DB.Preload("User").Order("created_at asc, id asc").Find(&profiles).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list homeowners")
		return
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		var bookingsCount int64
		_ = config.DB.Model(&models.Booking{}).Where("homeowner_id = ?", p.UserID).Count(&bookingsCount).Error
		idDoc, idStatus := latestHomeownerDocument(r, p.UserID)
		status := "pending"
		if !p.User.IsActive {
			status = "inactive"
		} else if strings.EqualFold(idStatus, "approved") {
			status = "active"
		}

		rows = append(rows, map[string]any{
			"id":             p.UserID,
			"profile_id":     p.ID,
			"user_id":        p.UserID,
			"user_email":     p.User.Email,
			"email":          p.User.Email,
			"full_name":      strings.TrimSpace(p.FirstName + " " + p.LastName),
			"first_name":     p.FirstName,
			"last_name":      p.LastName,
			"phone":          p.Phone,
			"barangay":       p.Barangay,
			"location":       p.Barangay,
			"status":         status,
			"id_status":      idStatus,
			"id_number":      fmt.Sprintf("HO-%d", p.ID),
			"id_document_url": buildPublicFileURL(r, idDoc.FilePath),
			"jobs_count":     bookingsCount,
			"created_at":     p.CreatedAt,
			"updated_at":     p.UpdatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"homeowners": rows})
}

// HandleTradesperson routes PATCH /api/admin/tradespeople/{id}/revoke|restore
func HandleTradesperson(w http.ResponseWriter, r *http.Request) {
	handleAdminUserStatus(w, r, "tradespeople")
}

// HandleHomeowner routes PATCH /api/admin/homeowners/{id}/revoke|restore
func HandleHomeowner(w http.ResponseWriter, r *http.Request) {
	handleAdminUserStatus(w, r, "homeowners")
}

// ListActivity handles GET /api/admin/activity?limit=6
func ListActivity(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	limit := 6
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			if parsed > 50 {
				parsed = 50
			}
			limit = parsed
		}
	}

	var activity []models.ActivityLog
	if err := config.DB.Order("created_at desc, id desc").Limit(limit).Find(&activity).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list activity")
		return
	}

	rows := make([]map[string]any, 0, len(activity))
	for _, item := range activity {
		rows = append(rows, map[string]any{
			"id":         item.ID,
			"title":      item.Title,
			"sub":        item.Sub,
			"type":       item.Type,
			"created_at": item.CreatedAt,
			"updated_at": item.UpdatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"activity": rows})
}

func handleAdminUserStatus(w http.ResponseWriter, r *http.Request, resource string) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	userID, action, ok := parseAdminActionPath(r.URL.Path, resource)
	if !ok {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		user = models.User{}
	}

	if user.ID == 0 {
		if resource == "homeowners" {
			var profile models.HomeownerProfile
			if err := config.DB.First(&profile, userID).Error; err == nil {
				if err := config.DB.First(&user, profile.UserID).Error; err != nil {
					writeError(w, http.StatusNotFound, "user not found")
					return
				}
			}
		} else if resource == "tradespeople" {
			var profile models.TradespersonProfile
			if err := config.DB.First(&profile, userID).Error; err == nil {
				if err := config.DB.First(&user, profile.UserID).Error; err != nil {
					writeError(w, http.StatusNotFound, "user not found")
					return
				}
			}
		}
	}

	if resource == "homeowners" && user.Role != "homeowner" {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	if resource == "tradespeople" && user.Role != "tradesperson" {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}

	targetName := adminUserDisplayName(user)
	now := time.Now()
	active := action == "restore"
	status := "revoked"
	logType := "user_revoked"
	if active {
		status = "restored"
		logType = "user_restored"
	}

	if err := config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&models.User{}).Where("id = ?", user.ID).
			Updates(map[string]any{"is_active": active, "updated_at": now}).Error; err != nil {
			return err
		}
		recordActivity(tx,
			fmt.Sprintf("%s %s", humanizeResource(resource), status),
			fmt.Sprintf("%s %s", targetName, action),
			logType,
		)
		return nil
	}); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update user status")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": fmt.Sprintf("%s %s", humanizeResource(resource), status),
		"user_id": user.ID,
		"status":  status,
	})
}

func HandleAdminDocumentFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 5 || parts[0] != "api" || parts[1] != "admin" || parts[2] != "documents" || parts[4] != "file" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	docID, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid document id")
		return
	}

	var doc models.VerificationDocument
	if err := config.DB.First(&doc, uint(docID)).Error; err != nil {
		writeError(w, http.StatusNotFound, "document not found")
		return
	}

	filePath := strings.TrimSpace(doc.FilePath)
	if filePath == "" {
		writeError(w, http.StatusNotFound, "document file not found")
		return
	}

	http.ServeFile(w, r, resolveStoredUploadPath(filePath))
}

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

func latestVerificationDocument(userID uint, documentGroup string) (models.VerificationDocument, bool) {
	var doc models.VerificationDocument
	err := config.DB.Where("user_id = ? AND document_group = ?", userID, documentGroup).
		Order("created_at desc").
		First(&doc).Error
	if err != nil {
		return models.VerificationDocument{}, false
	}
	return doc, true
}

func latestHomeownerDocument(r *http.Request, userID uint) (models.VerificationDocument, string) {
	doc, ok := latestVerificationDocument(userID, "government_id")
	if !ok {
		return models.VerificationDocument{}, "pending"
	}
	status := strings.ToLower(strings.TrimSpace(doc.Status))
	if status == "" {
		status = "pending"
	}
	_ = r
	return doc, status
}

func parseAdminActionPath(path, resource string) (uint, string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) != 5 || parts[0] != "api" || parts[1] != "admin" || parts[2] != resource {
		return 0, "", false
	}

	id, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil {
		return 0, "", false
	}

	action := parts[4]
	if action != "revoke" && action != "restore" {
		return 0, "", false
	}

	return uint(id), action, true
}

func recordActivity(tx *gorm.DB, title, sub, typ string) {
	entry := models.ActivityLog{
		Title: title,
		Sub:   sub,
		Type:  typ,
	}

	if tx != nil {
		_ = tx.Create(&entry).Error
		return
	}

	_ = config.DB.Create(&entry).Error
}

func humanizeResource(resource string) string {
	switch resource {
	case "homeowners":
		return "Homeowner"
	case "tradespeople":
		return "Tradesperson"
	default:
		return "User"
	}
}
