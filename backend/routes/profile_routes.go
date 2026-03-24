package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterProfileRoutes() {
	http.Handle("/api/profile/me", middleware.AuthMiddleware(http.HandlerFunc(controllers.GetMyProfile)))
}