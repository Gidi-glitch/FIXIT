package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"

	"gorm.io/gorm"
)

const (
	lockedMunicipality = "Calauan"
	lockedProvince     = "Laguna"
)

type createHomeownerAddressRequest struct {
	Label        string `json:"label"`
	Unit         string `json:"unit"`
	Street       string `json:"street"`
	Barangay     string `json:"barangay"`
	Municipality string `json:"municipality"`
	Province     string `json:"province"`
	IsPrimary    *bool  `json:"is_primary"`
}

type updateHomeownerAddressRequest struct {
	Label     *string `json:"label"`
	Unit      *string `json:"unit"`
	Street    *string `json:"street"`
	Barangay  *string `json:"barangay"`
	IsPrimary *bool   `json:"is_primary"`
}

func MyAddresses(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		listMyAddresses(w, r)
	case http.MethodPost:
		createMyAddress(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func MyAddressByIDRouter(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 4 || parts[0] != "api" || parts[1] != "profile" || parts[2] != "addresses" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	addressID, err := strconv.ParseUint(parts[3], 10, 64)
	if err != nil || addressID == 0 {
		writeError(w, http.StatusBadRequest, "invalid address id")
		return
	}

	if len(parts) == 4 {
		switch r.Method {
		case http.MethodPatch:
			updateMyAddress(w, r, uint(addressID))
		case http.MethodDelete:
			deleteMyAddress(w, r, uint(addressID))
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
		return
	}

	if len(parts) == 5 && parts[4] == "primary" {
		if r.Method != http.MethodPost {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
			return
		}
		setPrimaryMyAddress(w, r, uint(addressID))
		return
	}

	writeError(w, http.StatusNotFound, "not found")
}

func listMyAddresses(w http.ResponseWriter, r *http.Request) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	var addresses []models.HomeownerAddress
	if err := config.DB.Where("user_id = ?", homeownerID).
		Order("is_primary DESC").
		Order("updated_at DESC").
		Find(&addresses).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list addresses")
		return
	}

	if len(addresses) > 0 {
		hasPrimary := false
		for _, address := range addresses {
			if address.IsPrimary {
				hasPrimary = true
				break
			}
		}
		if !hasPrimary {
			first := addresses[0]
			_ = config.DB.Model(&models.HomeownerAddress{}).
				Where("id = ? AND user_id = ?", first.ID, homeownerID).
				Update("is_primary", true).Error
			_ = config.DB.Model(&models.HomeownerProfile{}).
				Where("user_id = ?", homeownerID).
				Update("barangay", first.Barangay).Error
			addresses[0].IsPrimary = true
		}
	}

	rows := make([]map[string]any, 0, len(addresses))
	for _, address := range addresses {
		rows = append(rows, serializeHomeownerAddress(address))
	}

	writeJSON(w, http.StatusOK, map[string]any{"addresses": rows})
}

func createMyAddress(w http.ResponseWriter, r *http.Request) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	var req createHomeownerAddressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	label := strings.TrimSpace(req.Label)
	if label == "" {
		label = "Home"
	}
	street := strings.TrimSpace(req.Street)
	if street == "" {
		writeError(w, http.StatusBadRequest, "street is required")
		return
	}
	barangay := strings.TrimSpace(req.Barangay)
	if barangay == "" {
		writeError(w, http.StatusBadRequest, "barangay is required")
		return
	}
	if strings.TrimSpace(req.Municipality) != "" && !strings.EqualFold(strings.TrimSpace(req.Municipality), lockedMunicipality) {
		writeError(w, http.StatusBadRequest, "municipality must be Calauan")
		return
	}
	if strings.TrimSpace(req.Province) != "" && !strings.EqualFold(strings.TrimSpace(req.Province), lockedProvince) {
		writeError(w, http.StatusBadRequest, "province must be Laguna")
		return
	}

	address := models.HomeownerAddress{
		UserID:       homeownerID,
		Label:        label,
		Unit:         strings.TrimSpace(req.Unit),
		Street:       street,
		Barangay:     barangay,
		Municipality: lockedMunicipality,
		Province:     lockedProvince,
	}

	err := config.DB.Transaction(func(tx *gorm.DB) error {
		var count int64
		if err := tx.Model(&models.HomeownerAddress{}).Where("user_id = ?", homeownerID).Count(&count).Error; err != nil {
			return err
		}

		isPrimary := req.IsPrimary != nil && *req.IsPrimary
		if count == 0 {
			isPrimary = true
		}

		if isPrimary {
			if err := tx.Model(&models.HomeownerAddress{}).Where("user_id = ?", homeownerID).Update("is_primary", false).Error; err != nil {
				return err
			}
		}

		address.IsPrimary = isPrimary
		if err := tx.Create(&address).Error; err != nil {
			return err
		}

		if address.IsPrimary {
			if err := tx.Model(&models.HomeownerProfile{}).Where("user_id = ?", homeownerID).Update("barangay", address.Barangay).Error; err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create address")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": "address created",
		"address": serializeHomeownerAddress(address),
	})
}

func updateMyAddress(w http.ResponseWriter, r *http.Request, addressID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	_, err := getOwnedHomeownerAddress(homeownerID, addressID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			writeError(w, http.StatusNotFound, "address not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to load address")
		return
	}

	var req updateHomeownerAddressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	updates := map[string]any{}
	if req.Label != nil {
		label := strings.TrimSpace(*req.Label)
		if label == "" {
			writeError(w, http.StatusBadRequest, "label cannot be empty")
			return
		}
		updates["label"] = label
	}
	if req.Unit != nil {
		updates["unit"] = strings.TrimSpace(*req.Unit)
	}
	if req.Street != nil {
		street := strings.TrimSpace(*req.Street)
		if street == "" {
			writeError(w, http.StatusBadRequest, "street cannot be empty")
			return
		}
		updates["street"] = street
	}
	if req.Barangay != nil {
		barangay := strings.TrimSpace(*req.Barangay)
		if barangay == "" {
			writeError(w, http.StatusBadRequest, "barangay cannot be empty")
			return
		}
		updates["barangay"] = barangay
	}

	makePrimary := req.IsPrimary != nil && *req.IsPrimary
	if len(updates) == 0 && !makePrimary {
		writeError(w, http.StatusBadRequest, "no updates provided")
		return
	}

	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if len(updates) > 0 {
			if err := tx.Model(&models.HomeownerAddress{}).
				Where("id = ? AND user_id = ?", addressID, homeownerID).
				Updates(updates).Error; err != nil {
				return err
			}
		}

		if makePrimary {
			if err := tx.Model(&models.HomeownerAddress{}).Where("user_id = ?", homeownerID).Update("is_primary", false).Error; err != nil {
				return err
			}
			if err := tx.Model(&models.HomeownerAddress{}).
				Where("id = ? AND user_id = ?", addressID, homeownerID).
				Update("is_primary", true).Error; err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update address")
		return
	}

	updatedAddress, err := getOwnedHomeownerAddress(homeownerID, addressID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated address")
		return
	}

	if updatedAddress.IsPrimary {
		if err := config.DB.Model(&models.HomeownerProfile{}).
			Where("user_id = ?", homeownerID).
			Update("barangay", updatedAddress.Barangay).Error; err != nil {
			writeError(w, http.StatusInternalServerError, "failed to sync primary barangay")
			return
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "address updated",
		"address": serializeHomeownerAddress(updatedAddress),
	})
}

func deleteMyAddress(w http.ResponseWriter, r *http.Request, addressID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	address, err := getOwnedHomeownerAddress(homeownerID, addressID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			writeError(w, http.StatusNotFound, "address not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to load address")
		return
	}

	var count int64
	if err := config.DB.Model(&models.HomeownerAddress{}).Where("user_id = ?", homeownerID).Count(&count).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to validate addresses")
		return
	}
	if count <= 1 {
		writeError(w, http.StatusConflict, "at least one address is required")
		return
	}

	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("id = ? AND user_id = ?", addressID, homeownerID).Delete(&models.HomeownerAddress{}).Error; err != nil {
			return err
		}

		if address.IsPrimary {
			var replacement models.HomeownerAddress
			if err := tx.Where("user_id = ?", homeownerID).
				Order("updated_at DESC").
				First(&replacement).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.HomeownerAddress{}).
				Where("user_id = ?", homeownerID).
				Update("is_primary", false).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.HomeownerAddress{}).
				Where("id = ?", replacement.ID).
				Update("is_primary", true).Error; err != nil {
				return err
			}

			if err := tx.Model(&models.HomeownerProfile{}).
				Where("user_id = ?", homeownerID).
				Update("barangay", replacement.Barangay).Error; err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete address")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"message": "address removed"})
}

func setPrimaryMyAddress(w http.ResponseWriter, r *http.Request, addressID uint) {
	homeownerID, ok := requireHomeowner(w, r)
	if !ok {
		return
	}

	address, err := getOwnedHomeownerAddress(homeownerID, addressID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			writeError(w, http.StatusNotFound, "address not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to load address")
		return
	}

	if address.IsPrimary {
		writeJSON(w, http.StatusOK, map[string]any{
			"message": "address already primary",
			"address": serializeHomeownerAddress(address),
		})
		return
	}

	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&models.HomeownerAddress{}).Where("user_id = ?", homeownerID).Update("is_primary", false).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.HomeownerAddress{}).
			Where("id = ? AND user_id = ?", addressID, homeownerID).
			Update("is_primary", true).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.HomeownerProfile{}).
			Where("user_id = ?", homeownerID).
			Update("barangay", address.Barangay).Error; err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to set primary address")
		return
	}

	updatedAddress, err := getOwnedHomeownerAddress(homeownerID, addressID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load updated address")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"message": "primary address updated",
		"address": serializeHomeownerAddress(updatedAddress),
	})
}

func getOwnedHomeownerAddress(homeownerID, addressID uint) (models.HomeownerAddress, error) {
	var address models.HomeownerAddress
	err := config.DB.Where("id = ? AND user_id = ?", addressID, homeownerID).First(&address).Error
	if err != nil {
		return models.HomeownerAddress{}, err
	}
	return address, nil
}

func serializeHomeownerAddress(address models.HomeownerAddress) map[string]any {
	return map[string]any{
		"id":           address.ID,
		"user_id":      address.UserID,
		"label":        address.Label,
		"unit":         address.Unit,
		"street":       address.Street,
		"barangay":     address.Barangay,
		"municipality": address.Municipality,
		"province":     address.Province,
		"is_primary":   address.IsPrimary,
		"isPrimary":    address.IsPrimary,
		"created_at":   address.CreatedAt,
		"updated_at":   address.UpdatedAt,
	}
}
