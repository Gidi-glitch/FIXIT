package routes

import (
	"net/http"

	"fixit-backend/controllers"
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
}
