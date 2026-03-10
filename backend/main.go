package main

import (
	"log"
	"net/http"

	"github.com/joho/godotenv"
	"fixit-backend/config"
	"fixit-backend/routes"
)

func main() {

	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	config.ConnectDB()

	routes.HomeownerRoutes()

	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("FIXIT backend is running"))
	})

	log.Println("🚀 Server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}