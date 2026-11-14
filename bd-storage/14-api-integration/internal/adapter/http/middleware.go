package http

import (
	"crypto/subtle"
	"net/http"

	"github.com/gin-gonic/gin"
)

const apiKeyHeader = "X-API-Key"

func requireAPIKey(key string) gin.HandlerFunc {
	expected := []byte(key)
	return func(c *gin.Context) {
		given := []byte(c.GetHeader(apiKeyHeader))
		if len(given) == 0 || subtle.ConstantTimeCompare(given, expected) != 1 {
			c.Header("WWW-Authenticate", apiKeyHeader)
			fail(c, http.StatusUnauthorized, "missing or invalid "+apiKeyHeader)
			return
		}
		c.Next()
	}
}
