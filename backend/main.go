package main

import (
	"log"
	"net/http"

	"fixit-backend/config"
	"fixit-backend/middleware"
	"fixit-backend/routes"

	"github.com/joho/godotenv"
)

func main() {

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	config.ConnectDB()

	routes.RegisterAuthRoutes()
	routes.RegisterProfileRoutes()
	routes.RegisterAdminRoutes()

	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("FIXIT backend is running"))
	})

	log.Println("🚀 Server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", middleware.CORSMiddleware(http.DefaultServeMux)))
}
