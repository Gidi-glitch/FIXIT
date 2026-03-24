package controllers

import (
	"fmt"
	"net/http"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
	"fixit-backend/services"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func RegisterHomeowner(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	if err := r.ParseMultipartForm(12 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form data")
		return
	}

	firstName := strings.TrimSpace(r.FormValue("first_name"))
	lastName := strings.TrimSpace(r.FormValue("last_name"))
	email := normalizeEmail(r.FormValue("email"))
	phone := strings.TrimSpace(r.FormValue("phone"))
	barangay := strings.TrimSpace(r.FormValue("barangay"))
	password := r.FormValue("password")
	idType := strings.TrimSpace(r.FormValue("id_type"))

	if firstName == "" || lastName == "" || email == "" || phone == "" || barangay == "" || password == "" || idType == "" {
		writeError(w, http.StatusBadRequest, "missing required registration fields")
		return
	}

	file, header, err := r.FormFile("id_document")
	if err != nil {
		file, header, err = r.FormFile("government_id_document")
	}
	if err != nil {
		writeError(w, http.StatusBadRequest, "government ID document is required")
		return
	}
	defer file.Close()

	if err := services.ValidateUpload(header); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to hash password")
		return
	}

	err = config.DB.Transaction(func(tx *gorm.DB) error {
		user := models.User{
			Email:        email,
			PasswordHash: string(hashedPassword),
			Role:         "homeowner",
			IsActive:     true,
		}

		if err := tx.Create(&user).Error; err != nil {
			return err
		}

		profile := models.HomeownerProfile{
			UserID:    user.ID,
			FirstName: firstName,
			LastName:  lastName,
			Phone:     phone,
			Barangay:  barangay,
			StatusID:  "pending",
		}
		if err := tx.Create(&profile).Error; err != nil {
			return err
		}

		storedName, filePath, err := services.SaveUploadedFile(file, header, "homeowners/ids")
		if err != nil {
			return err
		}

		document := models.VerificationDocument{
			UserID:        user.ID,
			DocumentGroup: "government_id",
			DocumentType:  idType,
			OriginalName:  header.Filename,
			StoredName:    storedName,
			FilePath:      filePath,
			MimeType:      header.Header.Get("Content-Type"),
			FileSize:      header.Size,
			Status:        "pending",
		}

		return tx.Create(&document).Error
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("failed to register homeowner: %v", err))
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{
		"message": "homeowner registered successfully",
	})
}
