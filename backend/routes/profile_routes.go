package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterProfileRoutes() {
	http.Handle("/api/profile/me", middleware.AuthMiddleware(http.HandlerFunc(controllers.ProfileMe)))
	http.Handle("/api/profile/me/name", middleware.AuthMiddleware(http.HandlerFunc(controllers.UpdateMyName)))
	http.Handle("/api/profile/me/email", middleware.AuthMiddleware(http.HandlerFunc(controllers.UpdateMyEmail)))
	http.Handle("/api/profile/me/password", middleware.AuthMiddleware(http.HandlerFunc(controllers.UpdateMyPassword)))
	http.Handle("/api/profile/photo", middleware.AuthMiddleware(http.HandlerFunc(controllers.UploadProfilePhoto)))
}
