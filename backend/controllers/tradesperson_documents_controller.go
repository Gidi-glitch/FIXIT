package controllers

import (
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
	"fixit-backend/services"
)

func TradespersonMyDocuments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var docs []models.VerificationDocument
	if err := config.DB.Where("user_id = ?", tradespersonID).Order("created_at ASC").Find(&docs).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load documents")
		return
	}

	rows := make([]map[string]any, 0, len(docs))
	for _, doc := range docs {
		rows = append(rows, map[string]any{
			"id":             doc.ID,
			"document_group": doc.DocumentGroup,
			"document_type":  doc.DocumentType,
			"original_name":  doc.OriginalName,
			"stored_name":    doc.StoredName,
			"mime_type":      doc.MimeType,
			"file_size":      doc.FileSize,
			"status":         doc.Status,
			"file_url":       buildPublicUploadURL(r, doc.FilePath),
			"created_at":     doc.CreatedAt,
			"updated_at":     doc.UpdatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"documents": rows})
}

func TradespersonMyDocumentByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 6 || parts[0] != "api" || parts[1] != "tradespeople" || parts[2] != "me" || parts[3] != "documents" || parts[5] != "replace" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	documentID, err := strconv.ParseUint(parts[4], 10, 64)
	if err != nil || documentID == 0 {
		writeError(w, http.StatusBadRequest, "invalid document id")
		return
	}

	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	replaceTradespersonDocumentByID(w, r, uint(documentID))
}

func replaceTradespersonDocumentByID(w http.ResponseWriter, r *http.Request, documentID uint) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var doc models.VerificationDocument
	if err := config.DB.Where("id = ? AND user_id = ?", documentID, tradespersonID).First(&doc).Error; err != nil {
		writeError(w, http.StatusNotFound, "document not found")
		return
	}

	if err := r.ParseMultipartForm(20 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form data")
		return
	}

	file, header, err := r.FormFile("document")
	if err != nil {
		file, header, err = r.FormFile("file")
	}
	if err != nil {
		file, header, err = r.FormFile("image")
	}
	if err != nil {
		writeError(w, http.StatusBadRequest, "document file is required")
		return
	}
	defer file.Close()

	if err := services.ValidateUpload(header); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	uploadSubdir := "tradespeople/documents"
	switch doc.DocumentGroup {
	case "government_id":
		uploadSubdir = "tradespeople/government_ids"
	case "license":
		uploadSubdir = "tradespeople/licenses"
	}

	storedName, filePath, err := services.SaveUploadedFile(file, header, uploadSubdir)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save document")
		return
	}

	updates := map[string]any{
		"original_name": header.Filename,
		"stored_name":   storedName,
		"file_path":     filePath,
		"mime_type":     header.Header.Get("Content-Type"),
		"file_size":     header.Size,
		"status":        "pending",
	}
	if err := config.DB.Model(&doc).Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update document")
		return
	}

	var refreshed models.VerificationDocument
	if err := config.DB.First(&refreshed, doc.ID).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated document")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "document replacement uploaded",
		"document": map[string]any{
			"id":             refreshed.ID,
			"document_group": refreshed.DocumentGroup,
			"document_type":  refreshed.DocumentType,
			"original_name":  refreshed.OriginalName,
			"stored_name":    refreshed.StoredName,
			"mime_type":      refreshed.MimeType,
			"file_size":      refreshed.FileSize,
			"status":         refreshed.Status,
			"file_url":       buildPublicUploadURL(r, refreshed.FilePath),
			"updated_at":     refreshed.UpdatedAt,
		},
	})
}
