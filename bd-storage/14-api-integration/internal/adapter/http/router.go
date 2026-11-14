package http

import (
	_ "embed"
	"net/http"

	"github.com/gin-gonic/gin"
)

//go:embed web/client.html
var clientPage []byte

func NewRouter(h *Handler, apiKey string) *gin.Engine {
	r := gin.Default()

	r.GET("/", func(c *gin.Context) {
		c.Data(http.StatusOK, "text/html; charset=utf-8", clientPage)
	})

	api := r.Group("/")
	api.Use(requireAPIKey(apiKey))
	api.GET("/titles/top", h.topTitles)
	api.GET("/titles/:title", h.checkoutsByTitle)
	api.GET("/search", h.search)
	api.POST("/checkouts", h.createCheckout)
	api.PUT("/checkouts", h.updateCheckout)
	api.DELETE("/checkouts", h.deleteCheckout)

	return r
}
