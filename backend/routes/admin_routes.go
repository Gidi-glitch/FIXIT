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
	// Trailing slash registers a subtree pattern that catches all sub-paths.
	http.Handle("/api/admin/documents/", admin(http.HandlerFunc(controllers.HandleDocument)))

	// GET  /api/admin/tradespeople?status=pending|approved|rejected
	http.Handle("/api/admin/tradespeople", admin(http.HandlerFunc(controllers.ListTradespeople)))
<<<<<<< HEAD
	http.Handle("/api/admin/tradespeople/", admin(http.HandlerFunc(controllers.HandleTradespersonAction)))

	// GET /api/admin/homeowners
	http.Handle("/api/admin/homeowners", admin(http.HandlerFunc(controllers.ListHomeowners)))
	http.Handle("/api/admin/homeowners/", admin(http.HandlerFunc(controllers.HandleHomeownerAction)))

	// GET /api/admin/activity?limit=6
	http.Handle("/api/admin/activity", admin(http.HandlerFunc(controllers.ListActivity)))
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
