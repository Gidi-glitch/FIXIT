package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterAdminRoutes() {
	admin := func(h http.Handler) http.Handler {
		return middleware.AuthMiddleware(middleware.AdminOnly(h))
	}

	http.Handle("/api/verifications", admin(http.HandlerFunc(controllers.ListVerifications)))
	http.Handle("/api/verifications/review", admin(http.HandlerFunc(controllers.ReviewVerification)))
	http.Handle("/api/verifications/", admin(http.HandlerFunc(controllers.VerificationByIDRouter)))

	// GET  /api/admin/documents?status=pending|approved|rejected
	http.Handle("/api/admin/documents", admin(http.HandlerFunc(controllers.ListDocuments)))

	// PATCH /api/admin/documents/{id}/approve
	// PATCH /api/admin/documents/{id}/reject
	// Trailing slash registers a subtree pattern that catches all sub-paths.
	http.Handle("/api/admin/documents/", admin(http.HandlerFunc(controllers.HandleDocument)))

	// GET  /api/admin/tradespeople?status=pending|approved|rejected
	http.Handle("/api/admin/tradespeople", admin(http.HandlerFunc(controllers.ListTradespeople)))
	http.Handle("/api/admin/tradespeople/", admin(http.HandlerFunc(controllers.AdminTradespersonByIDRouter)))
	http.Handle("/api/admin/homeowners", admin(http.HandlerFunc(controllers.ListHomeowners)))
	http.Handle("/api/admin/homeowners/", admin(http.HandlerFunc(controllers.AdminHomeownerByIDRouter)))
	http.Handle("/api/admin/activity", admin(http.HandlerFunc(controllers.ListActivity)))
	http.Handle("/api/admin/reviews", admin(http.HandlerFunc(controllers.ListAdminReviews)))
	http.Handle("/api/admin/reports", admin(http.HandlerFunc(controllers.ListAdminReports)))
	http.Handle("/api/admin/reports/", admin(http.HandlerFunc(controllers.AdminReportByIDRouter)))
}
