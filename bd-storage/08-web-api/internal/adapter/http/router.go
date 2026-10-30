package http

import "github.com/gin-gonic/gin"

func NewRouter(h *Handler) *gin.Engine {
	r := gin.Default()

	r.GET("/titles/top", h.topTitles)
	r.GET("/titles/:title", h.checkoutsByTitle)
	r.POST("/checkouts", h.createCheckout)
	r.PUT("/checkouts", h.updateCheckout)
	r.DELETE("/checkouts", h.deleteCheckout)

	return r
}
