package domain

import "errors"

var (
	ErrNotFound      = errors.New("not found")
	ErrTitleNotFound = errors.New("title not found")
	ErrInvalidInput  = errors.New("invalid input")
)

type TopTitle struct {
	Title string
	Total int64
}

type Checkout struct {
	FactID       int
	TitleID      int
	Title        string
	Year         int
	Month        int
	MaterialType string
	Checkouts    int
}

type NewCheckout struct {
	TitleID      int
	Year         int
	Month        int
	MaterialType string
	Checkouts    int
}
