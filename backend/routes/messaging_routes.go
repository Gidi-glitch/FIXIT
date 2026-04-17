package routes

import (
	"net/http"

	"fixit-backend/controllers"
	"fixit-backend/middleware"
)

func RegisterMessagingRoutes() {
	protected := func(h http.HandlerFunc) http.Handler {
		return middleware.AuthMiddleware(http.HandlerFunc(h))
	}

	http.Handle("/api/tradespeople", protected(controllers.ListMarketplaceTradespeople))
	http.Handle("/api/conversations", protected(controllers.ConversationsHandler))
	http.Handle("/api/conversations/", protected(controllers.ConversationHandler))
}
