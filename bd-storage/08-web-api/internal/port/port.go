package port

import (
	"context"

	"github.com/ItsXomyak/web-api/internal/domain"
)

type CheckoutService interface {
	TopTitles(ctx context.Context, year int, limit *int) ([]domain.TopTitle, error)
	CheckoutsByTitle(ctx context.Context, title string) ([]domain.Checkout, error)
	Create(ctx context.Context, c domain.NewCheckout) (domain.Checkout, error)
	UpdateCheckouts(ctx context.Context, factID, checkouts int) (domain.Checkout, error)
	Delete(ctx context.Context, factID int) error
}

type CheckoutRepository interface {
	TopTitles(ctx context.Context, year, limit int) ([]domain.TopTitle, error)
	CheckoutsByTitle(ctx context.Context, title string) ([]domain.Checkout, error)
	Insert(ctx context.Context, c domain.NewCheckout) (domain.Checkout, error)
	UpdateCheckouts(ctx context.Context, factID, checkouts int) (domain.Checkout, error)
	Delete(ctx context.Context, factID int) error
}
