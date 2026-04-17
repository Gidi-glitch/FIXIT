package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterVerificationRoutes() {
	admin := func(h http.Handler) http.Handler {
		return middleware.AuthMiddleware(middleware.AdminOnly(h))
	}

	http.Handle("/api/verifications", admin(http.HandlerFunc(controllers.ListVerifications)))
	http.Handle("/api/verifications/review", admin(http.HandlerFunc(controllers.ReviewVerification)))
	http.Handle("/api/verifications/", admin(http.HandlerFunc(controllers.HandleVerification)))
}
