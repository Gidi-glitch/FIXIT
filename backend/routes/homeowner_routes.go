package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func HomeownerRoutes() {

	http.HandleFunc("/api/homeowners/register", controllers.RegisterHomeowner)
	http.HandleFunc("/api/homeowners/login", controllers.LoginHomeowner)

	// Protected route
    http.Handle("/api/homeowners/profile", middleware.AuthMiddleware(http.HandlerFunc(controllers.GetProfile)))
}