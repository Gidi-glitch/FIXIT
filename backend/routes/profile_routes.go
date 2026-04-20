package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterProfileRoutes() {
	http.Handle("/api/profile/me", middleware.AuthMiddleware(http.HandlerFunc(controllers.ProfileMe)))
	http.Handle("/api/profile/photo", middleware.AuthMiddleware(http.HandlerFunc(controllers.UploadProfilePhoto)))
	http.Handle("/api/profile/addresses", middleware.AuthMiddleware(http.HandlerFunc(controllers.MyAddresses)))
	http.Handle("/api/profile/addresses/", middleware.AuthMiddleware(http.HandlerFunc(controllers.MyAddressByIDRouter)))
}
