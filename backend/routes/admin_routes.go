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

	// GET  /api/admin/documents?status=pending|approved|rejected
	http.Handle("/api/admin/documents", admin(http.HandlerFunc(controllers.ListDocuments)))

	// PATCH /api/admin/documents/{id}/approve
	// PATCH /api/admin/documents/{id}/reject
	// GET   /api/admin/documents/{id}/file
	// Trailing slash registers a subtree pattern that catches all sub-paths.
	http.Handle("/api/admin/documents/", admin(http.HandlerFunc(controllers.HandleDocument)))

	// GET  /api/admin/tradespeople?status=pending|approved|rejected
	http.Handle("/api/admin/tradespeople", admin(http.HandlerFunc(controllers.ListTradespeople)))
	// PATCH /api/admin/tradespeople/{id}/revoke
	// PATCH /api/admin/tradespeople/{id}/restore
	http.Handle("/api/admin/tradespeople/", admin(http.HandlerFunc(controllers.HandleTradesperson)))

	// GET  /api/admin/homeowners
	http.Handle("/api/admin/homeowners", admin(http.HandlerFunc(controllers.ListHomeowners)))
	// PATCH /api/admin/homeowners/{id}/revoke
	// PATCH /api/admin/homeowners/{id}/restore
	// PATCH /api/admin/homeowners/{id}/unreject
	http.Handle("/api/admin/homeowners/", admin(http.HandlerFunc(controllers.HandleHomeowner)))

	// GET  /api/admin/activity?limit=6
	http.Handle("/api/admin/activity", admin(http.HandlerFunc(controllers.ListActivity)))

	// GET  /api/verifications
	// POST /api/verifications/review
	// DELETE /api/verifications/{id}
	http.Handle("/api/verifications", admin(http.HandlerFunc(controllers.ListVerifications)))
	http.Handle("/api/verifications/review", admin(http.HandlerFunc(controllers.ReviewVerification)))
	http.Handle("/api/verifications/", admin(http.HandlerFunc(controllers.HandleVerification)))
}
