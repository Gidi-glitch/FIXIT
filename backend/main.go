package main

import (
	"log"
	"net/http"
	"strings"

	"fixit-backend/config"
	"fixit-backend/routes"
	"fixit-backend/services"

	"github.com/joho/godotenv"
)

func isAllowedOrigin(origin string) bool {
	if origin == "" {
		return false
	}

	allowed := []string{
		"http://localhost:3000",
		"http://127.0.0.1:3000",
		"http://localhost:3001",
		"http://127.0.0.1:3001",
		"http://10.27.1.216:3000",
	}

	for _, candidate := range allowed {
		if origin == candidate {
			return true
		}
	}

	// Allow local LAN dev origins without opening wildcard CORS in production-like environments.
	return strings.HasPrefix(origin, "http://192.168.") || strings.HasPrefix(origin, "http://10.")
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if isAllowedOrigin(origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		}

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	config.ConnectDB()

	// Start booking expiration scheduler
	stopChan := make(chan struct{})
	go services.StartExpirationScheduler(stopChan)

	routes.RegisterAuthRoutes()
	routes.RegisterProfileRoutes()
	routes.RegisterBookingRoutes()
	routes.RegisterAdminRoutes()
	http.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads"))))

	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("FIXIT backend is running"))
	})

	log.Println("🚀 Server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", withCORS(http.DefaultServeMux)))
}
