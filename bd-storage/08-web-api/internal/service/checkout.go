package service

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/web-api/internal/domain"
	"github.com/ItsXomyak/web-api/internal/port"
)

const (
	DefaultLimit = 10
	MinLimit     = 1
	MaxLimit     = 100
)

type CheckoutService struct {
	repo port.CheckoutRepository
}

func NewCheckoutService(repo port.CheckoutRepository) *CheckoutService {
	return &CheckoutService{repo: repo}
}

func invalid(format string, args ...any) error {
	return fmt.Errorf("%w: %s", domain.ErrInvalidInput, fmt.Sprintf(format, args...))
}

func (s *CheckoutService) TopTitles(ctx context.Context, year int, limit *int) ([]domain.TopTitle, error) {
	if year <= 0 {
		return nil, invalid("year must be positive")
	}
	l := DefaultLimit
	if limit != nil {
		l = *limit
	}
	if l < MinLimit || l > MaxLimit {
		return nil, invalid("limit must be between %d and %d", MinLimit, MaxLimit)
	}
	return s.repo.TopTitles(ctx, year, l)
}

func (s *CheckoutService) CheckoutsByTitle(ctx context.Context, title string) ([]domain.Checkout, error) {
	res, err := s.repo.CheckoutsByTitle(ctx, title)
	if err != nil {
		return nil, err
	}
	if len(res) == 0 {
		return nil, fmt.Errorf("%w: no checkouts for title %q", domain.ErrNotFound, title)
	}
	return res, nil
}

func (s *CheckoutService) Create(ctx context.Context, c domain.NewCheckout) (domain.Checkout, error) {
	switch {
	case c.TitleID <= 0:
		return domain.Checkout{}, invalid("title_id must be positive")
	case c.Year <= 0:
		return domain.Checkout{}, invalid("year must be positive")
	case c.Month < 1 || c.Month > 12:
		return domain.Checkout{}, invalid("month must be between 1 and 12")
	case c.MaterialType == "":
		return domain.Checkout{}, invalid("material_type must not be empty")
	case c.Checkouts < 0:
		return domain.Checkout{}, invalid("checkouts must not be negative")
	}
	return s.repo.Insert(ctx, c)
}

func (s *CheckoutService) UpdateCheckouts(ctx context.Context, factID, checkouts int) (domain.Checkout, error) {
	if factID <= 0 {
		return domain.Checkout{}, invalid("fact_id must be positive")
	}
	if checkouts < 0 {
		return domain.Checkout{}, invalid("checkouts must not be negative")
	}
	return s.repo.UpdateCheckouts(ctx, factID, checkouts)
}

func (s *CheckoutService) Delete(ctx context.Context, factID int) error {
	if factID <= 0 {
		return invalid("fact_id must be positive")
	}
	return s.repo.Delete(ctx, factID)
}
