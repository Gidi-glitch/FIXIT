package routes

import (
	"net/http"

	"fixit-backend/controllers"
)

func RegisterAuthRoutes() {
	// Backward-compatible alias for the admin site login
	http.HandleFunc("/api/users/login", controllers.Login)
	http.HandleFunc("/api/auth/login", controllers.Login)
	http.HandleFunc("/api/auth/homeowners/register", controllers.RegisterHomeowner)
	http.HandleFunc("/api/auth/tradespeople/register", controllers.RegisterTradesperson)
}
