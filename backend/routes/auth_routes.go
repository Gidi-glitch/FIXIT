package routes

import (
	"net/http"

	"fixit-backend/controllers"
<<<<<<< HEAD
)

func RegisterAuthRoutes() {
	// Backward-compatible alias for the admin site login
	http.HandleFunc("/api/users/login", controllers.Login)
	http.HandleFunc("/api/auth/login", controllers.Login)
	http.HandleFunc("/api/auth/homeowners/register", controllers.RegisterHomeowner)
	http.HandleFunc("/api/auth/tradespeople/register", controllers.RegisterTradesperson)
=======
	"fixit-backend/middleware"
)

func RegisterAuthRoutes() {
	http.HandleFunc("/api/auth/login", controllers.Login)
	http.HandleFunc("/api/auth/admin/register", controllers.RegisterAdmin)
	http.HandleFunc("/api/auth/homeowners/register", controllers.RegisterHomeowner)
	http.HandleFunc("/api/auth/tradespeople/register", controllers.RegisterTradesperson)
	http.HandleFunc("/api/auth/forgot-password", controllers.ForgotPassword)
	http.HandleFunc("/api/auth/verify-reset-code", controllers.VerifyResetCode)
	http.HandleFunc("/api/auth/reset-password", controllers.ResetPassword)
	http.Handle("/api/auth/change-password", middleware.AuthMiddleware(http.HandlerFunc(controllers.ChangePassword)))
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
