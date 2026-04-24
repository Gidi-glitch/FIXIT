package controllers

import (
	"net/http"
	"strconv"
	"strings"

	"fixit-backend/config"
	"fixit-backend/models"
)

// ListReports handles GET /api/admin/reports
// Optional query params:
//   - status=open|reviewing|resolved
//   - limit=1..500
func ListReports(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	limit := 500
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			if parsed > 500 {
				parsed = 500
			}
			limit = parsed
		}
	}

	query := config.DB.Preload("Booking").Preload("Booking.Homeowner").Preload("Booking.Tradesperson")
	if normalized := normalizeAdminReportStatusFilter(r.URL.Query().Get("status")); normalized != "" {
		query = query.Where("LOWER(status) = ?", normalized)
	}

	var issues []models.BookingIssue
	if err := query.Order("created_at desc, id desc").Limit(limit).Find(&issues).Error; err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list reports")
		return
	}

	rows := make([]map[string]any, 0, len(issues))
	for _, issue := range issues {
		reporterName := strings.TrimSpace(issue.ReporterName)
		if reporterName == "" {
			reporterName = adminUserDisplayName(issue.Booking.Homeowner)
		}

		targetName := strings.TrimSpace(issue.TargetName)
		if targetName == "" {
			targetName = adminUserDisplayName(issue.Booking.Tradesperson)
		}

		targetEmail := strings.TrimSpace(issue.TargetEmail)
		if targetEmail == "" {
			targetEmail = strings.TrimSpace(issue.Booking.Tradesperson.Email)
		}

		reporterRole := canonicalReportRole(issue.ReporterRole)
		if reporterRole == "" {
			reporterRole = "Homeowner"
		}

		targetRole := canonicalReportRole(issue.TargetRole)
		if targetRole == "" {
			targetRole = "Tradesman"
		}

		rows = append(rows, map[string]any{
			"id":             issue.ID,
			"booking_id":     issue.BookingID,
			"target_user_id": issue.Booking.TradespersonID,
			"source":         "booking_issue",
			"target_type":    targetRole,
			"target_name":    targetName,
			"target_email":   targetEmail,
			"reporter_name":  reporterName,
			"reporter_role":  reporterRole,
			"reason":         issue.Category,
			"details":        issue.Details,
			"status":         normalizeAdminReportStatus(issue.Status),
			"raw_status":     issue.Status,
			"booking_status": issue.Booking.Status,
			"submitted_at":   issue.CreatedAt,
			"updated_at":     issue.UpdatedAt,
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{"reports": rows})
}

func normalizeAdminReportStatus(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "resolved":
		return "Resolved"
	case "reviewing":
		return "Reviewing"
	case "under review", "open":
		return "Open"
	default:
		return "Open"
	}
}

func normalizeAdminReportStatusFilter(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "resolved":
		return "resolved"
	case "reviewing", "open", "under review":
		return "under review"
	default:
		return ""
	}
}

func canonicalReportRole(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "homeowner":
		return "Homeowner"
	case "tradesperson", "tradesman":
		return "Tradesman"
	case "admin":
		return "Administrator"
	default:
		return ""
	}
}
