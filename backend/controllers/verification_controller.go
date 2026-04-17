package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
)

type reviewVerificationRequest struct {
	VerificationID uint   `json:"verification_id"`
	Status         string `json:"status"`
}

func ListVerifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var docs []models.VerificationDocument
	if err := config.DB.Preload("User").Order("created_at desc").Find(&docs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list verifications")
		return
	}

	rows := make([]map[string]any, 0)
	for _, doc := range docs {
		vType, ok := adminVerificationType(doc.User.Role, doc.DocumentGroup)
		if !ok {
			continue
		}

		name := adminUserDisplayName(doc.User)
		rows = append(rows, map[string]any{
			"id":           doc.ID,
			"user_id":      doc.UserID,
			"user_name":    name,
			"type":         vType,
			"status":       doc.Status,
			"document_url": buildPublicFileURL(r, doc.FilePath),
			"created_at":   doc.CreatedAt,
			"updated_at":   doc.UpdatedAt,
		})
	}

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

	doc, err := getVerificationDocument(req.VerificationID)
	if err != nil {
		writeError(w, http.StatusNotFound, "verification not found")
		return
	}

	if doc.Status == "archived" {
		writeError(w, http.StatusConflict, "archived verification cannot be reviewed")
		return
	}

	if err := applyVerificationStatus(doc, status); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update verification")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "verification updated successfully",
		"id":      doc.ID,
		"status":  status,
	})
}

func HandleVerification(w http.ResponseWriter, r *http.Request) {
	idText := strings.TrimPrefix(r.URL.Path, "/api/verifications/")
	idText = strings.Trim(idText, "/")
	if idText == "" || strings.Contains(idText, "/") {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	id, err := strconv.ParseUint(idText, 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid verification id")
		return
	}

	doc, err := getVerificationDocument(uint(id))
	if err != nil {
		writeError(w, http.StatusNotFound, "verification not found")
		return
	}

	switch r.Method {
	case http.MethodDelete:
		if doc.Status == "archived" {
			writeError(w, http.StatusConflict, "verification is already archived")
			return
		}
		if err := applyVerificationStatus(doc, "archived"); err != nil {
			writeError(w, http.StatusInternalServerError, "failed to archive verification")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"message": "verification archived"})
	case http.MethodPatch:
		if doc.Status != "archived" {
			writeError(w, http.StatusConflict, "only archived verifications can be restored")
			return
		}
		if err := applyVerificationStatus(doc, "approved"); err != nil {
			writeError(w, http.StatusInternalServerError, "failed to restore verification")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"message": "verification restored"})
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func getVerificationDocument(id uint) (models.VerificationDocument, error) {
	var doc models.VerificationDocument
	err := config.DB.Preload("User").First(&doc, id).Error
	return doc, err
}

func applyVerificationStatus(doc models.VerificationDocument, status string) error {
	return config.DB.Transaction(func(tx *gorm.DB) error {
		now := time.Now()

		if doc.User.Role == "tradesperson" {
			if err := tx.Model(&models.VerificationDocument{}).
				Where("user_id = ? AND status <> ?", doc.UserID, "archived").
				Updates(map[string]any{"status": status, "updated_at": now}).Error; err != nil {
				return err
			}

			profileStatus := "pending"
			active := false
			switch status {
			case "approved":
				profileStatus = "approved"
				active = true
			case "rejected":
				profileStatus = "rejected"
			case "archived":
				profileStatus = "pending"
			}

			if err := tx.Model(&models.TradespersonProfile{}).
				Where("user_id = ?", doc.UserID).
				Updates(map[string]any{"verification_status": profileStatus, "updated_at": now}).Error; err != nil {
				return err
			}

			return tx.Model(&models.User{}).
				Where("id = ?", doc.UserID).
				Updates(map[string]any{"is_active": active, "updated_at": now}).Error
		}

		if err := tx.Model(&models.VerificationDocument{}).
			Where("id = ?", doc.ID).
			Updates(map[string]any{"status": status, "updated_at": now}).Error; err != nil {
			return err
		}

		active := false
		if status == "approved" {
			active = true
		}

		return tx.Model(&models.User{}).
			Where("id = ?", doc.UserID).
			Updates(map[string]any{"is_active": active, "updated_at": now}).Error
	})
}
