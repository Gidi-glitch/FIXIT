package controllers

import (
	"encoding/json"
	"net/http"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
)

type serviceAreaPayload struct {
	Barangays    []string `json:"barangays"`
	ServiceAreas []string `json:"service_areas"`
}

type tradeSkillsPayload struct {
	TradeCategory   *string  `json:"trade_category"`
	Specializations []string `json:"specializations"`
	ExperienceLevel *string  `json:"experience_level"`
	YearsExperience *int     `json:"years_experience"`
	RateRange       *string  `json:"rate_range"`
	Bio             *string  `json:"bio"`
}

func TradespersonServiceArea(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		getTradespersonServiceArea(w, r)
	case http.MethodPut:
		saveTradespersonServiceArea(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func TradespersonTradeSkills(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		getTradespersonTradeSkills(w, r)
	case http.MethodPut:
		saveTradespersonTradeSkills(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func getTradespersonServiceArea(w http.ResponseWriter, r *http.Request) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var profile models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", tradespersonID).First(&profile).Error; err != nil {
		writeError(w, http.StatusNotFound, "tradesperson profile not found")
		return
	}

	barangays := decodeStringList(profile.ServiceAreas)
	if len(barangays) == 0 {
		barangays = decodeStringList(profile.ServiceBarangay)
	}
	if len(barangays) == 0 {
		barangays = []string{profile.ServiceBarangay}
	}
	barangays = cleanUniqueStrings(barangays)

	writeJSON(w, http.StatusOK, map[string]any{
		"barangays":        barangays,
		"service_barangay": profile.ServiceBarangay,
	})
}

func saveTradespersonServiceArea(w http.ResponseWriter, r *http.Request) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var profile models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", tradespersonID).First(&profile).Error; err != nil {
		writeError(w, http.StatusNotFound, "tradesperson profile not found")
		return
	}

	var payload serviceAreaPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	barangays := payload.Barangays
	if len(barangays) == 0 {
		barangays = payload.ServiceAreas
	}
	barangays = cleanUniqueStrings(barangays)
	if len(barangays) == 0 {
		writeError(w, http.StatusBadRequest, "at least one barangay is required")
		return
	}

	encoded, _ := json.Marshal(barangays)
	updates := map[string]any{
		"service_areas": string(encoded),
	}

	homeBarangay := strings.TrimSpace(profile.ServiceBarangay)
	if homeBarangay == "" {
		homeBarangay = barangays[0]
		updates["service_barangay"] = homeBarangay
	}

	if err := config.DB.Model(&models.TradespersonProfile{}).Where("user_id = ?", tradespersonID).Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save service area")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":          "service area saved",
		"barangays":        barangays,
		"service_barangay": homeBarangay,
	})
}

func getTradespersonTradeSkills(w http.ResponseWriter, r *http.Request) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var profile models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", tradespersonID).First(&profile).Error; err != nil {
		writeError(w, http.StatusNotFound, "tradesperson profile not found")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"trade_skills": buildTradeSkillsResponse(profile)})
}

func saveTradespersonTradeSkills(w http.ResponseWriter, r *http.Request) {
	tradespersonID, ok := requireTradesperson(w, r)
	if !ok {
		return
	}

	var payload tradeSkillsPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	updates := map[string]any{}

	if payload.TradeCategory != nil {
		trade := strings.TrimSpace(*payload.TradeCategory)
		if trade == "" {
			writeError(w, http.StatusBadRequest, "trade_category cannot be empty")
			return
		}
		updates["trade_category"] = trade
	}

	if payload.Specializations != nil {
		specializations := cleanUniqueStrings(payload.Specializations)
		encoded, _ := json.Marshal(specializations)
		updates["specializations"] = string(encoded)
	}

	if payload.ExperienceLevel != nil {
		updates["experience_level"] = strings.TrimSpace(*payload.ExperienceLevel)
	}

	if payload.YearsExperience != nil {
		if *payload.YearsExperience < 0 {
			writeError(w, http.StatusBadRequest, "years_experience cannot be negative")
			return
		}
		updates["years_experience"] = *payload.YearsExperience
	}

	if payload.RateRange != nil {
		updates["rate_range"] = strings.TrimSpace(*payload.RateRange)
	}

	if payload.Bio != nil {
		updates["bio"] = strings.TrimSpace(*payload.Bio)
	}

	if len(updates) == 0 {
		writeError(w, http.StatusBadRequest, "no updates provided")
		return
	}

	if err := config.DB.Model(&models.TradespersonProfile{}).Where("user_id = ?", tradespersonID).Updates(updates).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to save trade skills")
		return
	}

	var refreshed models.TradespersonProfile
	if err := config.DB.Where("user_id = ?", tradespersonID).First(&refreshed).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated trade skills")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message":      "trade skills saved",
		"trade_skills": buildTradeSkillsResponse(refreshed),
	})
}

func decodeStringList(raw string) []string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return []string{}
	}

	var values []string
	if strings.HasPrefix(trimmed, "[") {
		if err := json.Unmarshal([]byte(trimmed), &values); err == nil {
			return cleanUniqueStrings(values)
		}
	}

	parts := strings.Split(trimmed, ",")
	return cleanUniqueStrings(parts)
}

func cleanUniqueStrings(values []string) []string {
	out := make([]string, 0, len(values))
	seen := map[string]bool{}
	for _, value := range values {
		cleaned := strings.TrimSpace(value)
		if cleaned == "" {
			continue
		}
		key := strings.ToLower(cleaned)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, cleaned)
	}
	return out
}

func buildTradeSkillsResponse(profile models.TradespersonProfile) map[string]any {
	return map[string]any{
		"trade_category":   profile.TradeCategory,
		"specializations":  decodeStringList(profile.Specializations),
		"experience_level": profile.ExperienceLevel,
		"years_experience": profile.YearsExperience,
		"rate_range":       profile.RateRange,
		"bio":              profile.Bio,
	}
}
