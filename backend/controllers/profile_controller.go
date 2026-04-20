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
		if err := config.DB.Where("user_id = ?", userID).First(&profile).Error; err == nil {
			return profile.FirstName, profile.LastName, profile.Barangay, profile.Bio, profile.Gender
		}
	} else if role == "tradesperson" {
		var profile models.TradespersonProfile
		if err := config.DB.Where("user_id = ?", userID).First(&profile).Error; err == nil {
			return profile.FirstName, profile.LastName, profile.ServiceBarangay, profile.Bio, profile.Gender
		}
	}

	return "", "", "", "", ""
}

func GetMyProfile(w http.ResponseWriter, r *http.Request) {
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

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}

	var documents []models.VerificationDocument
	config.DB.Where("user_id = ?", user.ID).Find(&documents)

	firstName, lastName, barangay, bio, gender := getUserProfileDetails(user.ID, user.Role)

	var photo models.UserProfilePhoto
	profileImageURL := ""
	if err := config.DB.Where("user_id = ?", user.ID).First(&photo).Error; err == nil {
		profileImageURL = buildPublicFileURL(r, photo.FilePath)
	}

	response := map[string]any{
		"user": map[string]any{
			"id":                user.ID,
			"email":             user.Email,
			"role":              user.Role,
			"is_active":         user.IsActive,
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

	var req updateMyProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		writeError(w, http.StatusNotFound, "user not found")
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
