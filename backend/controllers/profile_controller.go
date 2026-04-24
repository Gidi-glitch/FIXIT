package controllers

import (
	"encoding/json"
	"errors"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/models"
	"fixit-backend/services"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type updateProfileNameRequest struct {
	FullName string `json:"full_name"`
}

type updateProfileEmailRequest struct {
	Email           string `json:"email"`
	CurrentPassword string `json:"current_password"`
}

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
	trimmed := publicUploadRelativePath(filePath)
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

func adminDisplayNameFromEmail(email string) string {
	local := strings.TrimSpace(strings.Split(email, "@")[0])
	if local == "" {
		return "Admin User"
	}

	parts := strings.FieldsFunc(local, func(r rune) bool {
		return r == '.' || r == '_' || r == '-'
	})
	if len(parts) == 0 {
		return "Admin User"
	}

	for i, part := range parts {
		if part == "" {
			continue
		}
		parts[i] = strings.ToUpper(part[:1]) + strings.ToLower(part[1:])
	}

	return strings.TrimSpace(strings.Join(parts, " "))
}

func getCurrentUserFromRequest(r *http.Request) (models.User, bool) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		return models.User{}, false
	}

	userID, ok := claims["user_id"].(float64)
	if !ok {
		return models.User{}, false
	}

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		return models.User{}, false
	}

	return user, true
}

func getOrCreateAdminProfile(user models.User) (models.AdminProfile, error) {
	var profile models.AdminProfile
	if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err == nil {
		return profile, nil
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return models.AdminProfile{}, err
	}

	profile = models.AdminProfile{
		UserID:   user.ID,
		FullName: adminDisplayNameFromEmail(user.Email),
	}
	if err := config.DB.Create(&profile).Error; err != nil {
		return models.AdminProfile{}, err
	}

	return profile, nil
}

func splitFullName(fullName string) (string, string) {
	parts := strings.Fields(strings.TrimSpace(fullName))
	if len(parts) == 0 {
		return "", ""
	}
	if len(parts) == 1 {
		return parts[0], ""
	}
	return parts[0], strings.Join(parts[1:], " ")
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

	if user.Role == "admin" {
		adminProfile, err := getOrCreateAdminProfile(user)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "failed to load admin profile")
			return
		}

		response["user"] = map[string]any{
			"id":                user.ID,
			"email":             user.Email,
			"role":              user.Role,
			"is_active":         user.IsActive,
			"full_name":         adminProfile.FullName,
			"updated_at":        adminProfile.UpdatedAt,
			"profile_image_url": profileImageURL,
		}
		response["profile"] = adminProfile
		writeJSON(w, http.StatusOK, response)
		return
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

func UpdateMyProfileName(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok := getCurrentUserFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req updateProfileNameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		writeError(w, http.StatusBadRequest, "full_name cannot be empty")
		return
	}

	now := time.Now()
	switch user.Role {
	case "admin":
		profile, err := getOrCreateAdminProfile(user)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update admin profile")
			return
		}

		if err := config.DB.Model(&profile).Updates(map[string]any{
			"full_name":  fullName,
			"updated_at": now,
		}).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update admin profile")
			return
		}
		recordActivity(nil, "Admin profile updated", "Updated admin display name", "admin_updated")

	case "homeowner":
		var profile models.HomeownerProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "homeowner profile not found")
			return
		}

		firstName, lastName := splitFullName(fullName)
		updates := map[string]any{
			"first_name": firstName,
			"last_name":  lastName,
			"updated_at": now,
		}
		if err := config.DB.Model(&profile).Updates(updates).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update homeowner profile")
			return
		}
		recordActivity(nil, "Homeowner profile updated", "Updated profile name", "profile_updated")

	case "tradesperson":
		var profile models.TradespersonProfile
		if err := config.DB.Where("user_id = ?", user.ID).First(&profile).Error; err != nil {
			writeError(w, http.StatusNotFound, "tradesperson profile not found")
			return
		}

		firstName, lastName := splitFullName(fullName)
		updates := map[string]any{
			"first_name": firstName,
			"last_name":  lastName,
			"updated_at": now,
		}
		if err := config.DB.Model(&profile).Updates(updates).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to update tradesperson profile")
			return
		}
		recordActivity(nil, "Tradesperson profile updated", "Updated profile name", "profile_updated")

	default:
		writeError(w, http.StatusBadRequest, "unsupported user role")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "profile name updated successfully"})
}

func UpdateMyProfileEmail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok := getCurrentUserFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req updateProfileEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	email := normalizeEmail(req.Email)
	currentPassword := strings.TrimSpace(req.CurrentPassword)
	if email == "" || currentPassword == "" {
		writeError(w, http.StatusBadRequest, "email and current_password are required")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	var existing models.User
	if err := config.DB.Where("email = ? AND id <> ?", email, user.ID).First(&existing).Error; err == nil {
		writeError(w, http.StatusConflict, "email is already in use")
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		writeError(w, http.StatusInternalServerError, "failed to validate email")
		return
	}

	if err := config.DB.Model(&user).Update("email", email).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update email")
		return
	}
	recordActivity(nil, "Account email updated", email, "admin_updated")

	writeJSON(w, http.StatusOK, map[string]string{"message": "email updated successfully"})
}

func UpdateMyPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch && r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, ok := getCurrentUserFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req changePasswordRequest
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
	recordActivity(nil, "Password updated", "Changed account password", "admin_updated")

	writeJSON(w, http.StatusOK, map[string]string{"message": "password updated successfully"})
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

	case "admin":
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
