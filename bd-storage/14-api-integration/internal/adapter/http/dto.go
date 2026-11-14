package http

import (
	"encoding/xml"

	"github.com/ItsXomyak/api-integration/internal/domain"
)

type topQuery struct {
	Year   int    `form:"year" binding:"required"`
	Limit  *int   `form:"limit"`
	Format string `form:"format" binding:"omitempty,oneof=json xml"`
}

type searchQuery struct {
	Q string `form:"q" binding:"required"`
}

type deleteQuery struct {
	FactID int `form:"fact_id" binding:"required"`
}

type createCheckoutRequest struct {
	TitleID      int    `json:"title_id" binding:"required"`
	Year         int    `json:"year" binding:"required"`
	Month        int    `json:"month" binding:"required"`
	MaterialType string `json:"material_type" binding:"required"`
	Checkouts    *int   `json:"checkouts" binding:"required"`
}

type updateCheckoutRequest struct {
	FactID    int  `json:"fact_id" binding:"required"`
	Checkouts *int `json:"checkouts" binding:"required"`
}

type topTitleResponse struct {
	Title string `json:"title" xml:"title"`
	Total int64  `json:"total" xml:"total"`
}

type topTitlesXML struct {
	XMLName xml.Name           `xml:"titles"`
	Items   []topTitleResponse `xml:"item"`
}

type searchResponse struct {
	TitleID int    `json:"title_id"`
	Title   string `json:"title"`
	Creator string `json:"creator"`
}

type checkoutResponse struct {
	FactID       int    `json:"fact_id"`
	TitleID      int    `json:"title_id"`
	Title        string `json:"title"`
	Year         int    `json:"year"`
	Month        int    `json:"month"`
	MaterialType string `json:"material_type"`
	Checkouts    int    `json:"checkouts"`
}

func (r createCheckoutRequest) toDomain() domain.NewCheckout {
	return domain.NewCheckout{
		TitleID:      r.TitleID,
		Year:         r.Year,
		Month:        r.Month,
		MaterialType: r.MaterialType,
		Checkouts:    *r.Checkouts,
	}
}

func toTopResponse(in []domain.TopTitle) []topTitleResponse {
	out := make([]topTitleResponse, len(in))
	for i, t := range in {
		out[i] = topTitleResponse{Title: t.Title, Total: t.Total}
	}
	return out
}

func toCheckoutResponse(c domain.Checkout) checkoutResponse {
	return checkoutResponse(c)
}

func toCheckoutResponses(in []domain.Checkout) []checkoutResponse {
	out := make([]checkoutResponse, len(in))
	for i, c := range in {
		out[i] = toCheckoutResponse(c)
	}
	return out
}

func toSearchResponses(in []domain.TitleInfo) []searchResponse {
	out := make([]searchResponse, len(in))
	for i, t := range in {
		out[i] = searchResponse{TitleID: t.TitleID, Title: t.Title, Creator: t.Creator}
	}
	return out
}
