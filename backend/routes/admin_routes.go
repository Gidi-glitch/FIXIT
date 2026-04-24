package routes

import (
	"net/http"
	"strings"

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
	http.Handle("/api/admin/documents/", admin(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(strings.TrimRight(r.URL.Path, "/"), "/file") {
			controllers.HandleAdminDocumentFile(w, r)
			return
		}
		controllers.HandleDocument(w, r)
	})))

	// GET  /api/admin/tradespeople?status=pending|approved|rejected
	http.Handle("/api/admin/tradespeople", admin(http.HandlerFunc(controllers.ListTradespeople)))
	http.Handle("/api/admin/tradespeople/", admin(http.HandlerFunc(controllers.HandleTradesperson)))

	// GET  /api/admin/homeowners
	http.Handle("/api/admin/homeowners", admin(http.HandlerFunc(controllers.ListHomeowners)))
	http.Handle("/api/admin/homeowners/", admin(http.HandlerFunc(controllers.HandleHomeowner)))

	// GET  /api/admin/activity?limit=6
	http.Handle("/api/admin/activity", admin(http.HandlerFunc(controllers.ListActivity)))

	// GET  /api/admin/reports?status=open|reviewing|resolved
	http.Handle("/api/admin/reports", admin(http.HandlerFunc(controllers.ListReports)))
}
