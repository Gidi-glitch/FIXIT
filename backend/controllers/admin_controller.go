package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
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
	query := config.DB.Preload("User")
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
		if err := config.DB.
			Where("user_id IN ? AND document_group = ?", userIDs, "government_id").
			Order("created_at desc").
			Find(&docs).Error; err == nil {
			for _, d := range docs {
				if _, exists := docMap[d.UserID]; !exists {
					docMap[d.UserID] = d
				}
			}
		}
	}

	rows := make([]map[string]any, 0, len(profiles))
	for _, p := range profiles {
		fullName := strings.TrimSpace(p.FirstName + " " + p.LastName)
		row := map[string]any{
			"id":         p.ID,
			"user_id":    p.UserID,
			"email":      p.User.Email,
			"full_name":  fullName,
			"barangay":   p.Barangay,
			"created_at": p.CreatedAt,
		}

		if doc, ok := docMap[p.UserID]; ok {
			row["id_status"] = doc.Status
			row["id_document_url"] = fmt.Sprintf("/api/admin/documents/%d/file", doc.ID)
			row["id_document_type"] = doc.DocumentType
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
	query := config.DB.Preload("User").
		Where("document_group IN ?", []string{"government_id", "license"})
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
		switch d.DocumentGroup {
		case "license":
			vType = "tradesperson_license"
		case "government_id":
			if d.User.Role != "homeowner" {
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
			"document_url": fmt.Sprintf("/api/admin/documents/%d/file", d.ID),
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

	syncTradespersonStatus(doc.UserID)

	writeJSON(w, http.StatusOK, map[string]any{
		"message":         "verification " + body.Status,
		"verification_id": doc.ID,
		"status":          body.Status,
	})
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
