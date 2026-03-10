package controllers

import (
	"encoding/json"
	"net/http"

	"fixit-backend/config"
	"fixit-backend/models"
	"fixit-backend/middleware"

	"golang.org/x/crypto/bcrypt"
	"github.com/golang-jwt/jwt/v5"
)

type RegisterHomeownerRequest struct {
	FullName string `json:"full_name"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Barangay string `json:"barangay"`
	Password string `json:"password"`
}

func RegisterHomeowner(w http.ResponseWriter, r *http.Request) {

	var req RegisterHomeownerRequest

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), 10)
	if err != nil {
		http.Error(w, "Error hashing password", http.StatusInternalServerError)
		return
	}

	homeowner := models.Homeowner{
		FullName: req.FullName,
		Email:    req.Email,
		Phone:    req.Phone,
		Barangay: req.Barangay,
		Password: string(hashedPassword),
	}

	result := config.DB.Create(&homeowner)

	if result.Error != nil {
		http.Error(w, result.Error.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	json.NewEncoder(w).Encode(map[string]string{
		"message": "Homeowner registered successfully",
	})
}

func LoginHomeowner(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var loginData struct {
        Email    string `json:"email"`
        Password string `json:"password"`
    }

    err := json.NewDecoder(r.Body).Decode(&loginData)
    if err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    var homeowner models.Homeowner
    result := config.DB.Where("email = ?", loginData.Email).First(&homeowner)
    if result.Error != nil {
        http.Error(w, "Invalid email or password", http.StatusUnauthorized)
        return
    }

    // Compare hashed password
    err = bcrypt.CompareHashAndPassword([]byte(homeowner.Password), []byte(loginData.Password))
    if err != nil {
        http.Error(w, "Invalid email or password", http.StatusUnauthorized)
        return
    }

	// Generate JWT token
    token, err := middleware.GenerateJWT(homeowner)
    if err != nil {
        http.Error(w, "Error generating token", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "message": "Login successful",
		"token":   token,
    })
}

func GetProfile(w http.ResponseWriter, r *http.Request) {
    // Get JWT claims from context
    claims, ok := r.Context().Value(middleware.UserContextKey).(jwt.MapClaims)
    if !ok {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }

    // Return homeowner info
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "user_id": claims["user_id"],
        "email":   claims["email"],
    })
}