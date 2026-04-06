package controllers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/models"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UpdateEmailRequest struct {
	CurrentPassword string `json:"current_password"`
	Email           string `json:"email"`
}

type UpdatePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

type UpdateSecurityRequest struct {
	TwoFactorEnabled bool `json:"two_factor_enabled"`
}

func currentUserFromRequest(r *http.Request) (*models.User, error) {
	claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
	if !ok {
		return nil, errors.New("unauthorized")
	}

	userID, ok := claims["user_id"].(float64)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		return nil, err
	}

	return &user, nil
}

func GetMyProfile(w http.ResponseWriter, r *http.Request) {
	user, err := currentUserFromRequest(r)
	if err != nil {
		status := http.StatusUnauthorized
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		writeError(w, status, err.Error())
		return
	}

	var documents []models.VerificationDocument
	config.DB.Where("user_id = ?", user.ID).Find(&documents)

	response := map[string]any{
		"user": map[string]any{
			"id":                 user.ID,
			"email":              user.Email,
			"role":               user.Role,
			"is_active":          user.IsActive,
			"two_factor_enabled": user.TwoFactorEnabled,
			"updated_at":         user.UpdatedAt,
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

func UpdateMyEmail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, err := currentUserFromRequest(r)
	if err != nil {
		status := http.StatusUnauthorized
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		writeError(w, status, err.Error())
		return
	}

	var req UpdateEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	email := normalizeEmail(req.Email)
	if email == "" {
		writeError(w, http.StatusBadRequest, "email is required")
		return
	}
	if req.CurrentPassword == "" {
		writeError(w, http.StatusBadRequest, "current password is required")
		return
	}
	if email == user.Email {
		writeError(w, http.StatusBadRequest, "new email must be different")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	var duplicate models.User
	if err := config.DB.Where("email = ? AND id <> ?", email, user.ID).First(&duplicate).Error; err == nil {
		writeError(w, http.StatusConflict, "email is already in use")
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		writeError(w, http.StatusInternalServerError, "failed to validate email")
		return
	}

	if err := config.DB.Model(user).Update("email", email).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update email")
		return
	}

	user.Email = email
	writeJSON(w, http.StatusOK, map[string]any{
		"message": "email updated successfully",
		"user": map[string]any{
			"id":                 user.ID,
			"email":              user.Email,
			"role":               user.Role,
			"is_active":          user.IsActive,
			"two_factor_enabled": user.TwoFactorEnabled,
		},
	})
}

func UpdateMyPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, err := currentUserFromRequest(r)
	if err != nil {
		status := http.StatusUnauthorized
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		writeError(w, status, err.Error())
		return
	}

	var req UpdatePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.CurrentPassword == "" || req.NewPassword == "" {
		writeError(w, http.StatusBadRequest, "current password and new password are required")
		return
	}
	if len(strings.TrimSpace(req.NewPassword)) < 8 {
		writeError(w, http.StatusBadRequest, "new password must be at least 8 characters")
		return
	}
	if req.NewPassword == req.CurrentPassword {
		writeError(w, http.StatusBadRequest, "new password must be different")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		writeError(w, http.StatusUnauthorized, "current password is incorrect")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to secure new password")
		return
	}

	if err := config.DB.Model(user).Update("password_hash", string(hash)).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update password")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "password updated successfully",
	})
}

func UpdateMySecurity(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	user, err := currentUserFromRequest(r)
	if err != nil {
		status := http.StatusUnauthorized
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		writeError(w, status, err.Error())
		return
	}

	var req UpdateSecurityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := config.DB.Model(user).Update("two_factor_enabled", req.TwoFactorEnabled).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update security settings")
		return
	}

	user.TwoFactorEnabled = req.TwoFactorEnabled
	writeJSON(w, http.StatusOK, map[string]any{
		"message": "security settings updated successfully",
		"user": map[string]any{
			"id":                 user.ID,
			"email":              user.Email,
			"role":               user.Role,
			"is_active":          user.IsActive,
			"two_factor_enabled": user.TwoFactorEnabled,
		},
	})
}
