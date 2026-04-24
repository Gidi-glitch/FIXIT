package controllers

import (
	"encoding/json"
	"errors"
	"net/http"
	"path/filepath"
	"strings"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/models"
	"fixit-backend/services"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type updateMyProfileRequest struct {
	FirstName *string `json:"first_name"`
	LastName  *string `json:"last_name"`
	Phone     *string `json:"phone"`
	Email     *string `json:"email"`
	Bio       *string `json:"bio"`
	Gender    *string `json:"gender"`
	Barangay  *string `json:"barangay"`
}

type updateMyNameRequest struct {
	FullName string `json:"full_name"`
}

type updateMyEmailRequest struct {
	Email           string `json:"email"`
	CurrentPassword string `json:"current_password"`
}

type updateMyPasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

func ProfileMe(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		GetMyProfile(w, r)
	case http.MethodPut:
		UpdateMyProfile(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func buildPublicFileURL(r *http.Request, filePath string) string {
	trimmed := strings.TrimPrefix(filepath.ToSlash(filePath), "uploads/")
	if trimmed == "" {
		return ""
	}

	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-Proto")); forwarded != "" {
		scheme = forwarded
	}

	return scheme + "://" + r.Host + "/uploads/" + trimmed
}

func getUserProfileDetails(userID uint, role string) (string, string, string, string, string) {
	if role == "homeowner" {
		var profile models.HomeownerProfile
		if tx := config.DB.Where("user_id = ?", userID).Limit(1).Find(&profile); tx.Error == nil && tx.RowsAffected > 0 {
			return profile.FirstName, profile.LastName, profile.Barangay, profile.Bio, profile.Gender
		}
	} else if role == "tradesperson" {
		var profile models.TradespersonProfile
		if tx := config.DB.Where("user_id = ?", userID).Limit(1).Find(&profile); tx.Error == nil && tx.RowsAffected > 0 {
			return profile.FirstName, profile.LastName, profile.ServiceBarangay, profile.Bio, profile.Gender
		}
	}

	return "", "", "", "", ""
}

func getAuthenticatedUser(r *http.Request) (models.User, bool, int, string) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		return models.User{}, false, http.StatusUnauthorized, "unauthorized"
	}

	userID, ok := claims["user_id"].(float64)
	if !ok {
		return models.User{}, false, http.StatusUnauthorized, "invalid token claims"
	}

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		return models.User{}, false, http.StatusNotFound, "user not found"
	}

	return user, true, 0, ""
}

func buildUserFullName(user models.User, firstName string, lastName string) string {
	if trimmed := strings.TrimSpace(user.FullName); trimmed != "" {
		return trimmed
	}

	fullName := strings.TrimSpace(firstName + " " + lastName)
	if fullName != "" {
		return fullName
	}

	return ""
}

func GetMyProfile(w http.ResponseWriter, r *http.Request) {
	user, ok, status, message := getAuthenticatedUser(r)
	if !ok {
		writeError(w, status, message)
		return
	}

	var documents []models.VerificationDocument
	config.DB.Where("user_id = ?", user.ID).Find(&documents)

	firstName, lastName, barangay, bio, gender := getUserProfileDetails(user.ID, user.Role)
	fullName := buildUserFullName(user, firstName, lastName)

	var photo models.UserProfilePhoto
	profileImageURL := ""
	if tx := config.DB.Where("user_id = ?", user.ID).Limit(1).Find(&photo); tx.Error == nil && tx.RowsAffected > 0 {
		profileImageURL = buildPublicFileURL(r, photo.FilePath)
	}

	response := map[string]any{
		"user": map[string]any{
			"id":                user.ID,
			"email":             user.Email,
			"role":              user.Role,
			"is_active":         user.IsActive,
			"full_name":         fullName,
			"first_name":        firstName,
			"last_name":         lastName,
			"bio":               bio,
			"gender":            gender,
			"barangay":          barangay,
			"profile_image_url": profileImageURL,
		},
		"documents": documents,
	}

	if user.Role == "homeowner" {
		var profile models.HomeownerProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err == nil {
			response["profile"] = profile
		}
	} else if user.Role == "tradesperson" {
		var profile models.TradespersonProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err == nil {
			response["profile"] = profile
		}
	}

	writeJSON(w, http.StatusOK, response)
}

func UpdateMyProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok, status, message := getAuthenticatedUser(r)
	if !ok {
		writeError(w, status, message)
		return
	}

	var req updateMyProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	userUpdates := map[string]any{}
	if req.Email != nil {
		email := normalizeEmail(*req.Email)
		if email == "" {
			writeError(w, http.StatusBadRequest, "email cannot be empty")
			return
		}

		var existing models.User
		err := config.DB.Where("email = ? AND id <> ?", email, user.ID).First(&existing).Error
		if err == nil {
			writeError(w, http.StatusConflict, "email is already in use")
			return
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			writeError(w, http.StatusInternalServerError, "failed to validate email")
			return
		}

		if user.Email != email {
			userUpdates["email"] = email
		}
	}

	if len(userUpdates) > 0 {
		if err := config.DB.Model(&user).Updates(userUpdates).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update user")
			return
		}
	}

	switch user.Role {
	case "homeowner":
		var profile models.HomeownerProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "homeowner profile not found")
			return
		}

		updates := map[string]any{}
		if req.FirstName != nil {
			firstName := strings.TrimSpace(*req.FirstName)
			if firstName == "" {
				writeError(w, http.StatusBadRequest, "first_name cannot be empty")
				return
			}
			updates["first_name"] = firstName
		}
		if req.LastName != nil {
			lastName := strings.TrimSpace(*req.LastName)
			if lastName == "" {
				writeError(w, http.StatusBadRequest, "last_name cannot be empty")
				return
			}
			updates["last_name"] = lastName
		}
		if req.Phone != nil {
			phone := strings.TrimSpace(*req.Phone)
			if phone == "" {
				writeError(w, http.StatusBadRequest, "phone cannot be empty")
				return
			}
			updates["phone"] = phone
		}
		if req.Barangay != nil {
			barangay := strings.TrimSpace(*req.Barangay)
			if barangay == "" {
				writeError(w, http.StatusBadRequest, "barangay cannot be empty")
				return
			}
			updates["barangay"] = barangay
		}
		if req.Gender != nil {
			updates["gender"] = strings.TrimSpace(*req.Gender)
		}
		if req.Bio != nil {
			updates["bio"] = strings.TrimSpace(*req.Bio)
		}

		if len(updates) > 0 {
			if err := config.DB.Model(&profile).Updates(updates).Error; err != nil {
				writeError(w, http.StatusInternalServerError, "failed to update homeowner profile")
				return
			}
		}

	case "tradesperson":
		var profile models.TradespersonProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "tradesperson profile not found")
			return
		}

		updates := map[string]any{}
		if req.FirstName != nil {
			firstName := strings.TrimSpace(*req.FirstName)
			if firstName == "" {
				writeError(w, http.StatusBadRequest, "first_name cannot be empty")
				return
			}
			updates["first_name"] = firstName
		}
		if req.LastName != nil {
			lastName := strings.TrimSpace(*req.LastName)
			if lastName == "" {
				writeError(w, http.StatusBadRequest, "last_name cannot be empty")
				return
			}
			updates["last_name"] = lastName
		}
		if req.Phone != nil {
			phone := strings.TrimSpace(*req.Phone)
			if phone == "" {
				writeError(w, http.StatusBadRequest, "phone cannot be empty")
				return
			}
			updates["phone"] = phone
		}
		if req.Barangay != nil {
			barangay := strings.TrimSpace(*req.Barangay)
			if barangay == "" {
				writeError(w, http.StatusBadRequest, "barangay cannot be empty")
				return
			}

			serviceAreas := syncServiceAreasWithNewHomeBarangay(
				profile.ServiceAreas,
				profile.ServiceBarangay,
				barangay,
			)

			encodedAreas, err := json.Marshal(serviceAreas)
			if err != nil {
				writeError(w, http.StatusInternalServerError, "failed to update service area")
				return
			}

			updates["service_barangay"] = barangay
			updates["service_areas"] = string(encodedAreas)
		}
		if req.Bio != nil {
			updates["bio"] = strings.TrimSpace(*req.Bio)
		}
		if req.Gender != nil {
			updates["gender"] = strings.TrimSpace(*req.Gender)
		}

		if len(updates) > 0 {
			if err := config.DB.Model(&profile).Updates(updates).Error; err != nil {
				writeError(w, http.StatusInternalServerError, "failed to update tradesperson profile")
				return
			}
		}

	default:
		writeError(w, http.StatusBadRequest, "unsupported user role")
		return
	}

	GetMyProfile(w, r)
}

func UpdateMyName(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok, status, message := getAuthenticatedUser(r)
	if !ok {
		writeError(w, status, message)
		return
	}

	var req updateMyNameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		writeError(w, http.StatusBadRequest, "full_name is required")
		return
	}

	if err := config.DB.Model(&user).Update("full_name", fullName).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update name")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":   "name updated successfully",
		"full_name": fullName,
	})
}

func UpdateMyEmail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok, status, message := getAuthenticatedUser(r)
	if !ok {
		writeError(w, status, message)
		return
	}

	var req updateMyEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	email := normalizeEmail(req.Email)
	if email == "" {
		writeError(w, http.StatusBadRequest, "email is required")
		return
	}

	if strings.TrimSpace(req.CurrentPassword) == "" {
		writeError(w, http.StatusBadRequest, "current_password is required")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	var existing models.User
	err := config.DB.Where("email = ? AND id <> ?", email, user.ID).First(&existing).Error
	if err == nil {
		writeError(w, http.StatusConflict, "email is already in use")
		return
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		writeError(w, http.StatusInternalServerError, "failed to validate email")
		return
	}

	if err := config.DB.Model(&user).Update("email", email).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update email")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "email updated successfully",
		"email":   email,
	})
}

func UpdateMyPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok, status, message := getAuthenticatedUser(r)
	if !ok {
		writeError(w, status, message)
		return
	}

	var req updateMyPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	currentPassword := strings.TrimSpace(req.CurrentPassword)
	newPassword := strings.TrimSpace(req.NewPassword)
	if currentPassword == "" || newPassword == "" {
		writeError(w, http.StatusBadRequest, "current_password and new_password are required")
		return
	}
	if len(newPassword) < 8 {
		writeError(w, http.StatusBadRequest, "new_password must be at least 8 characters")
		return
	}
	if currentPassword == newPassword {
		writeError(w, http.StatusBadRequest, "new_password must be different from current_password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to hash password")
		return
	}

	if err := config.DB.Model(&user).Update("password_hash", string(hashedPassword)).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update password")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "password updated successfully",
	})
}

func syncServiceAreasWithNewHomeBarangay(
	rawServiceAreas string,
	previousBarangay string,
	newBarangay string,
) []string {
	previousBarangay = strings.TrimSpace(previousBarangay)
	newBarangay = strings.TrimSpace(newBarangay)

	serviceAreas := decodeStringList(rawServiceAreas)
	if len(serviceAreas) == 0 && previousBarangay != "" {
		serviceAreas = []string{previousBarangay}
	}

	replaced := false
	if previousBarangay != "" {
		for i, area := range serviceAreas {
			if strings.EqualFold(strings.TrimSpace(area), previousBarangay) {
				serviceAreas[i] = newBarangay
				replaced = true
			}
		}
	}

	if !replaced && newBarangay != "" {
		serviceAreas = append(serviceAreas, newBarangay)
	}

	serviceAreas = cleanUniqueStrings(serviceAreas)

	if newBarangay != "" {
		hasNewBarangay := false
		for _, area := range serviceAreas {
			if strings.EqualFold(strings.TrimSpace(area), newBarangay) {
				hasNewBarangay = true
				break
			}
		}
		if !hasNewBarangay {
			serviceAreas = append(serviceAreas, newBarangay)
		}
	}

	return cleanUniqueStrings(serviceAreas)
}

func UploadProfilePhoto(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	userID, ok := claims["user_id"].(float64)
	if !ok {
		writeError(w, http.StatusUnauthorized, "invalid token claims")
		return
	}

	if err := r.ParseMultipartForm(8 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form data")
		return
	}

	file, header, err := r.FormFile("profile_image")
	if err != nil {
		file, header, err = r.FormFile("image")
	}
	if err != nil {
		writeError(w, http.StatusBadRequest, "profile image is required")
		return
	}
	defer file.Close()

	if err := services.ValidateUpload(header); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext == ".pdf" {
		writeError(w, http.StatusBadRequest, "profile image must be jpg, jpeg, or png")
		return
	}

	storedName, filePath, err := services.SaveUploadedFile(file, header, "profiles")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save profile image")
		return
	}

	var photo models.UserProfilePhoto
	err = config.DB.Where("user_id = ?", uint(userID)).First(&photo).Error
	if err == nil {
		photo.OriginalName = header.Filename
		photo.StoredName = storedName
		photo.FilePath = filePath
		photo.MimeType = header.Header.Get("Content-Type")
		photo.FileSize = header.Size
		if err := config.DB.Save(&photo).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update profile image")
			return
		}
	} else {
		photo = models.UserProfilePhoto{
			UserID:       uint(userID),
			OriginalName: header.Filename,
			StoredName:   storedName,
			FilePath:     filePath,
			MimeType:     header.Header.Get("Content-Type"),
			FileSize:     header.Size,
		}
		if err := config.DB.Create(&photo).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to save profile image")
			return
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":           "profile image uploaded",
		"profile_image_url": buildPublicFileURL(r, photo.FilePath),
	})
}
