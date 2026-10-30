package http

import (
	"errors"
	"net/http"

	"github.com/ItsXomyak/web-api/internal/domain"
	"github.com/ItsXomyak/web-api/internal/port"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc port.CheckoutService
}

func NewHandler(svc port.CheckoutService) *Handler {
	return &Handler{svc: svc}
}

func fail(c *gin.Context, status int, msg string) {
	c.AbortWithStatusJSON(status, gin.H{"error": msg})
}

func handleError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, domain.ErrInvalidInput):
		fail(c, http.StatusUnprocessableEntity, err.Error())
	case errors.Is(err, domain.ErrTitleNotFound):
		fail(c, http.StatusNotFound, "title_id does not exist")
	case errors.Is(err, domain.ErrNotFound):
		fail(c, http.StatusNotFound, err.Error())
	default:
		c.Error(err)
		fail(c, http.StatusInternalServerError, "internal server error")
	}
}

func (h *Handler) topTitles(c *gin.Context) {
	var q topQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		fail(c, http.StatusUnprocessableEntity, "invalid query: year is required, limit must be an integer")
		return
	}
	res, err := h.svc.TopTitles(c.Request.Context(), q.Year, q.Limit)
	if err != nil {
		handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, toTopResponse(res))
}

func (h *Handler) checkoutsByTitle(c *gin.Context) {
	res, err := h.svc.CheckoutsByTitle(c.Request.Context(), c.Param("title"))
	if err != nil {
		handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, toCheckoutResponses(res))
}

func (h *Handler) createCheckout(c *gin.Context) {
	var req createCheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fail(c, http.StatusUnprocessableEntity, "invalid body: "+err.Error())
		return
	}
	res, err := h.svc.Create(c.Request.Context(), req.toDomain())
	if err != nil {
		handleError(c, err)
		return
	}
	c.JSON(http.StatusCreated, toCheckoutResponse(res))
}

func (h *Handler) updateCheckout(c *gin.Context) {
	var req updateCheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fail(c, http.StatusUnprocessableEntity, "invalid body: "+err.Error())
		return
	}
	res, err := h.svc.UpdateCheckouts(c.Request.Context(), req.FactID, *req.Checkouts)
	if err != nil {
		handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, toCheckoutResponse(res))
}

func (h *Handler) deleteCheckout(c *gin.Context) {
	var q deleteQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		fail(c, http.StatusUnprocessableEntity, "invalid query: fact_id is required")
		return
	}
	if err := h.svc.Delete(c.Request.Context(), q.FactID); err != nil {
		handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"deleted": q.FactID})
}
