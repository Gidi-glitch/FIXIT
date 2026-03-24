package controllers

import (
    "bytes"
    "crypto/rand"
    "encoding/json"
    "log"
    "math/big"
    "net/http"
    "strings"
    "sync"
    "time"
	"os"

    "fixit-backend/config"
    "fixit-backend/middleware"
    "fixit-backend/models"

    "golang.org/x/crypto/bcrypt"
)

type LoginRequest struct {
    Email    string `json:"email"`
    Password string `json:"password"`
}

type forgotPasswordRequest struct {
    Email string `json:"email"`
}

type verifyResetCodeRequest struct {
    Email string `json:"email"`
    OTP   string `json:"otp"`
}

type resetPasswordRequest struct {
    Email       string `json:"email"`
    OTP         string `json:"otp"`
    NewPassword string `json:"new_password"`
}

type resetCodeEntry struct {
    Code      string
    ExpiresAt time.Time
    Verified  bool
}

var resetCodes = struct {
    sync.Mutex
    ByEmail map[string]resetCodeEntry
}{
    ByEmail: make(map[string]resetCodeEntry),
}

const (
    resetCodeLength = 6
    resetCodeTTL    = 10 * time.Minute
)

// ------------------------- LOGIN -------------------------

func Login(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        writeError(w, http.StatusMethodNotAllowed, "method not allowed")
        return
    }

    var req LoginRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    email := normalizeEmail(req.Email)
    if email == "" || req.Password == "" {
        writeError(w, http.StatusBadRequest, "email and password are required")
        return
    }

    var user models.User
    if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
        writeError(w, http.StatusUnauthorized, "invalid email or password")
        return
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
        writeError(w, http.StatusUnauthorized, "invalid email or password")
        return
    }

    token, err := middleware.GenerateJWT(user)
    if err != nil {
        writeError(w, http.StatusInternalServerError, "failed to generate token")
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "message": "login successful",
        "token":   token,
        "user": map[string]any{
            "id":    user.ID,
            "email": user.Email,
            "role":  user.Role,
        },
    })
}

// -------------------- FORGOT PASSWORD --------------------

func ForgotPassword(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        writeError(w, http.StatusMethodNotAllowed, "method not allowed")
        return
    }

    var req forgotPasswordRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    email := normalizeEmail(req.Email)
    if email == "" {
        writeError(w, http.StatusBadRequest, "email is required")
        return
    }

    var user models.User
    if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
        // Keep response generic (safer); does not reveal account existence
        writeJSON(w, http.StatusOK, map[string]string{
            "message": "if the account exists, a reset code has been sent",
        })
        return
    }

    code, err := generateOTP(resetCodeLength)
    if err != nil {
        writeError(w, http.StatusInternalServerError, "failed to generate reset code")
        return
    }

    resetCodes.Lock()
    resetCodes.ByEmail[email] = resetCodeEntry{
        Code:      code,
        ExpiresAt: time.Now().Add(resetCodeTTL),
        Verified:  false,
    }
    resetCodes.Unlock()

	if err := sendResetOTPEmail(email, code); err != nil {
		// optional: remove code if email sending fails
		resetCodes.Lock()
		delete(resetCodes.ByEmail, email)
		resetCodes.Unlock()

		writeError(w, http.StatusInternalServerError, "failed to send reset code email")
		return
	}

    // Local testing only: print OTP in backend logs
    log.Printf("[RESET OTP] email=%s code=%s expires_in=%s", email, code, resetCodeTTL.String())

    writeJSON(w, http.StatusOK, map[string]string{
        "message": "if the account exists, a reset code has been sent",
    })
}

func VerifyResetCode(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        writeError(w, http.StatusMethodNotAllowed, "method not allowed")
        return
    }

    var req verifyResetCodeRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    email := normalizeEmail(req.Email)
    otp := strings.TrimSpace(req.OTP)
    if email == "" || otp == "" {
        writeError(w, http.StatusBadRequest, "email and otp are required")
        return
    }

    resetCodes.Lock()
    entry, ok := resetCodes.ByEmail[email]
    if !ok {
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "invalid or expired reset code")
        return
    }

    if time.Now().After(entry.ExpiresAt) {
        delete(resetCodes.ByEmail, email)
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "invalid or expired reset code")
        return
    }

    if otp != entry.Code {
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "invalid or expired reset code")
        return
    }

    entry.Verified = true
    resetCodes.ByEmail[email] = entry
    resetCodes.Unlock()

    writeJSON(w, http.StatusOK, map[string]string{
        "message": "reset code verified",
    })
}

func ResetPassword(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        writeError(w, http.StatusMethodNotAllowed, "method not allowed")
        return
    }

    var req resetPasswordRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    email := normalizeEmail(req.Email)
    otp := strings.TrimSpace(req.OTP)
    newPassword := req.NewPassword

    if email == "" || otp == "" || newPassword == "" {
        writeError(w, http.StatusBadRequest, "email, otp, and new_password are required")
        return
    }
    if len(newPassword) < 8 {
        writeError(w, http.StatusBadRequest, "new_password must be at least 8 characters")
        return
    }

    resetCodes.Lock()
    entry, ok := resetCodes.ByEmail[email]
    if !ok {
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "invalid or expired reset code")
        return
    }
    if time.Now().After(entry.ExpiresAt) {
        delete(resetCodes.ByEmail, email)
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "invalid or expired reset code")
        return
    }
    if !entry.Verified || otp != entry.Code {
        resetCodes.Unlock()
        writeError(w, http.StatusBadRequest, "reset code not verified")
        return
    }
    resetCodes.Unlock()

    var user models.User
    if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
        writeError(w, http.StatusBadRequest, "invalid account")
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

    resetCodes.Lock()
    delete(resetCodes.ByEmail, email)
    resetCodes.Unlock()

    writeJSON(w, http.StatusOK, map[string]string{
        "message": "password reset successful",
    })
}

// ------------------------- HELPERS ------------------------

func generateOTP(length int) (string, error) {
    const digits = "0123456789"
    var b strings.Builder
    b.Grow(length)

    for i := 0; i < length; i++ {
        n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
        if err != nil {
            return "", err
        }
        b.WriteByte(digits[n.Int64()])
    }
    return b.String(), nil
}

func normalizeEmail(email string) string {
    return strings.ToLower(strings.TrimSpace(email))
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
    writeJSON(w, status, map[string]string{"message": message})
}

func sendResetOTPEmail(toEmail, otp string) error {
    apiKey := os.Getenv("RESEND_API_KEY")
    fromEmail := os.Getenv("RESEND_FROM_EMAIL")

    if apiKey == "" || fromEmail == "" {
        return writeSimpleError("missing RESEND_API_KEY or RESEND_FROM_EMAIL")
    }

    payload := map[string]any{
        "from":    fromEmail,
        "to":      []string{toEmail},
        "subject": "FIXIT Password Reset Code",
        "html": "<p>Your FIXIT password reset code is:</p>" +
            "<h2>" + otp + "</h2>" +
            "<p>This code will expire in 10 minutes.</p>" +
            "<p>If you did not request this, ignore this email.</p>",
    }

    bodyBytes, err := json.Marshal(payload)
    if err != nil {
        return err
    }

    req, err := http.NewRequest(http.MethodPost, "https://api.resend.com/emails", bytes.NewBuffer(bodyBytes))
    if err != nil {
        return err
    }
    req.Header.Set("Authorization", "Bearer "+apiKey)
    req.Header.Set("Content-Type", "application/json")

    client := &http.Client{Timeout: 15 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        var resendErr map[string]any
        _ = json.NewDecoder(resp.Body).Decode(&resendErr)
        log.Printf("Resend API error: status=%d body=%v", resp.StatusCode, resendErr)
        return writeSimpleError("resend API failed")
    }

    return nil
}

func writeSimpleError(message string) error {
    return &simpleError{msg: message}
}

type simpleError struct {
    msg string
}

func (e *simpleError) Error() string {
    return e.msg
}