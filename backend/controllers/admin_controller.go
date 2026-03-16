package controllers

import (
	"encoding/json"
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
