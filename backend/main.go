package main

import (
	"log"
	"net/http"
<<<<<<< HEAD
	"os"
	"strings"
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

	"fixit-backend/config"
	"fixit-backend/routes"

	"github.com/joho/godotenv"
)

<<<<<<< HEAD
func loadEnv() {
	candidates := []string{
		".env",
		"backend/.env",
		"services/.env",
		"backend/services/.env",
	}

	for _, path := range candidates {
		if _, err := os.Stat(path); err != nil {
			continue
		}
		if err := godotenv.Load(path); err == nil {
			log.Printf("✅ Loaded environment from %s", path)
			return
		}
	}

	log.Println("⚠️ No .env file found in expected paths; using process environment variables")
}

func main() {

	loadEnv()
=======
func main() {

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

	config.ConnectDB()

	routes.RegisterAuthRoutes()
	routes.RegisterProfileRoutes()
<<<<<<< HEAD
	routes.RegisterAdminRoutes()
	routes.RegisterVerificationRoutes()
	routes.RegisterMessagingRoutes()
	routes.RegisterBookingRoutes()
=======
	routes.RegisterBookingRoutes()
	routes.RegisterAdminRoutes()
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
	http.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads"))))

	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("FIXIT backend is running"))
	})

	log.Println("🚀 Server running on port 8080")
<<<<<<< HEAD
	log.Fatal(http.ListenAndServe(":8080", withCORS(http.DefaultServeMux)))
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := strings.TrimSpace(r.Header.Get("Origin"))
		if origin != "" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
		}

		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
=======
	log.Fatal(http.ListenAndServe(":8080", nil))
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
}
