package controllers

import (
<<<<<<< HEAD
=======
	"encoding/json"
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
	"fixit-backend/services"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func RegisterTradesperson(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	if err := r.ParseMultipartForm(20 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form data")
		return
	}

	firstName := strings.TrimSpace(r.FormValue("first_name"))
	lastName := strings.TrimSpace(r.FormValue("last_name"))
	email := normalizeEmail(r.FormValue("email"))
	phone := strings.TrimSpace(r.FormValue("phone"))
	password := r.FormValue("password")
	tradeCategory := strings.TrimSpace(r.FormValue("trade_category"))
	serviceBarangay := strings.TrimSpace(r.FormValue("service_barangay"))
	bio := strings.TrimSpace(r.FormValue("bio"))
	governmentIDType := strings.TrimSpace(r.FormValue("government_id_type"))
	licenseType := strings.TrimSpace(r.FormValue("license_type"))
	yearsExperienceValue := strings.TrimSpace(r.FormValue("years_experience"))

	yearsExperience, err := strconv.Atoi(yearsExperienceValue)
	if err != nil {
		writeError(w, http.StatusBadRequest, "years_experience must be a valid number")
		return
	}

	if firstName == "" || lastName == "" || email == "" || phone == "" || password == "" || tradeCategory == "" || serviceBarangay == "" || governmentIDType == "" || licenseType == "" {
		writeError(w, http.StatusBadRequest, "missing required registration fields")
		return
	}

	governmentFile, governmentHeader, err := r.FormFile("government_id_document")
	if err != nil {
		writeError(w, http.StatusBadRequest, "government ID document is required")
		return
	}
	defer governmentFile.Close()

	licenseFile, licenseHeader, err := r.FormFile("license_document")
	if err != nil {
		writeError(w, http.StatusBadRequest, "license document is required")
		return
	}
	defer licenseFile.Close()

	if err := services.ValidateUpload(governmentHeader); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := services.ValidateUpload(licenseHeader); err != nil {
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
			Role:         "tradesperson",
			IsActive:     true,
		}

		if err := tx.Create(&user).Error; err != nil {
			return err
		}

<<<<<<< HEAD
=======
		initialServiceAreas, _ := json.Marshal([]string{serviceBarangay})

>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
		profile := models.TradespersonProfile{
			UserID:             user.ID,
			FirstName:          firstName,
			LastName:           lastName,
			Phone:              phone,
			TradeCategory:      tradeCategory,
			YearsExperience:    yearsExperience,
			ServiceBarangay:    serviceBarangay,
<<<<<<< HEAD
=======
			ServiceAreas:       string(initialServiceAreas),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
			Bio:                bio,
			VerificationStatus: "pending",
		}

		if err := tx.Create(&profile).Error; err != nil {
			return err
		}

		governmentStoredName, governmentPath, err := services.SaveUploadedFile(governmentFile, governmentHeader, "tradespeople/government_ids")
		if err != nil {
			return err
		}

		licenseStoredName, licensePath, err := services.SaveUploadedFile(licenseFile, licenseHeader, "tradespeople/licenses")
		if err != nil {
			return err
		}

		governmentDocument := models.VerificationDocument{
			UserID:        user.ID,
			DocumentGroup: "government_id",
			DocumentType:  governmentIDType,
			OriginalName:  governmentHeader.Filename,
			StoredName:    governmentStoredName,
			FilePath:      governmentPath,
			MimeType:      governmentHeader.Header.Get("Content-Type"),
			FileSize:      governmentHeader.Size,
			Status:        "pending",
		}

		if err := tx.Create(&governmentDocument).Error; err != nil {
			return err
		}

		licenseDocument := models.VerificationDocument{
			UserID:        user.ID,
			DocumentGroup: "license",
			DocumentType:  licenseType,
			OriginalName:  licenseHeader.Filename,
			StoredName:    licenseStoredName,
			FilePath:      licensePath,
			MimeType:      licenseHeader.Header.Get("Content-Type"),
			FileSize:      licenseHeader.Size,
			Status:        "pending",
		}

		return tx.Create(&licenseDocument).Error
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("failed to register tradesperson: %v", err))
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{
		"message": "tradesperson registered successfully",
	})
<<<<<<< HEAD
}
=======
}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
