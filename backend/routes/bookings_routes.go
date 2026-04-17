package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterBookingRoutes() {
	protected := func(h http.HandlerFunc) http.Handler {
		return middleware.AuthMiddleware(http.HandlerFunc(h))
	}

	http.Handle("/api/bookings", protected(controllers.BookingsHandler))
	http.Handle("/api/bookings/", protected(controllers.BookingHandler))
}
