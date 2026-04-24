package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterBookingRoutes() {
	auth := func(h http.Handler) http.Handler {
		return middleware.AuthMiddleware(h)
	}

	http.Handle("/api/tradespeople", auth(http.HandlerFunc(controllers.ListTradespeopleForHomeowner)))
	http.Handle("/api/tradespeople/me/on-duty", auth(http.HandlerFunc(controllers.UpdateMyOnDutyStatus)))
	http.Handle("/api/reviews/tradesperson/me", auth(http.HandlerFunc(controllers.TradespersonMyReviews)))
	http.Handle("/api/tradespeople/me/documents", auth(http.HandlerFunc(controllers.TradespersonMyDocuments)))
	http.Handle("/api/tradespeople/me/documents/", auth(http.HandlerFunc(controllers.TradespersonMyDocumentByIDRouter)))
	http.Handle("/api/tradespeople/me/service-area", auth(http.HandlerFunc(controllers.TradespersonServiceArea)))
	http.Handle("/api/tradespeople/me/trade-skills", auth(http.HandlerFunc(controllers.TradespersonTradeSkills)))
	http.Handle("/api/requests/incoming", auth(http.HandlerFunc(controllers.TradespersonIncomingRequests)))
	http.Handle("/api/requests/", auth(http.HandlerFunc(controllers.TradespersonRequestByIDRouter)))
	http.Handle("/api/jobs/tradesperson", auth(http.HandlerFunc(controllers.TradespersonJobs)))
	http.Handle("/api/jobs/", auth(http.HandlerFunc(controllers.TradespersonJobByIDRouter)))
	http.Handle("/api/conversations", auth(http.HandlerFunc(controllers.ConversationsRoot)))
	http.Handle("/api/conversations/", auth(http.HandlerFunc(controllers.ConversationByIDRouter)))
	http.Handle("/api/bookings", auth(http.HandlerFunc(controllers.BookingsRoot)))
	http.Handle("/api/bookings/homeowner", auth(http.HandlerFunc(controllers.HomeownerBookings)))
	http.Handle("/api/bookings/", auth(http.HandlerFunc(controllers.BookingByIDRouter)))

	// Notification routes
	http.Handle("/api/notifications", auth(http.HandlerFunc(controllers.GetMyNotifications)))
	http.Handle("/api/notifications/unread", auth(http.HandlerFunc(controllers.GetMyUnreadNotifications)))
	http.Handle("/api/notifications/unread-count", auth(http.HandlerFunc(controllers.GetUnreadCount)))
	http.Handle("/api/notifications/mark-all-read", auth(http.HandlerFunc(controllers.MarkAllNotificationsAsRead)))
	http.Handle("/api/notifications/mark-read/", auth(http.HandlerFunc(controllers.MarkNotificationAsRead)))
}
