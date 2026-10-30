package postgres

import (
	"context"
	"errors"

	"github.com/ItsXomyak/web-api/internal/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const fkViolation = "23503"

type CheckoutRepo struct {
	pool *pgxpool.Pool
}

func New(ctx context.Context, dsn string) (*CheckoutRepo, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return &CheckoutRepo{pool: pool}, nil
}

func (r *CheckoutRepo) Close() {
	r.pool.Close()
}

func (r *CheckoutRepo) TopTitles(ctx context.Context, year, limit int) ([]domain.TopTitle, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT t.title, SUM(f.checkouts)::bigint AS total
		FROM checkout_facts f
		JOIN titles t ON t.title_id = f.title_id
		WHERE f.checkoutyear = $1 AND t.title IS NOT NULL
		GROUP BY t.title
		ORDER BY total DESC, t.title
		LIMIT $2`, year, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	res := []domain.TopTitle{}
	for rows.Next() {
		var t domain.TopTitle
		if err := rows.Scan(&t.Title, &t.Total); err != nil {
			return nil, err
		}
		res = append(res, t)
	}
	return res, rows.Err()
}

func (r *CheckoutRepo) CheckoutsByTitle(ctx context.Context, title string) ([]domain.Checkout, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT f.fact_id, f.title_id, t.title,
		       COALESCE(f.checkoutyear, 0), COALESCE(f.checkoutmonth, 0),
		       COALESCE(f.materialtype, ''), COALESCE(f.checkouts, 0)
		FROM checkout_facts f
		JOIN titles t ON t.title_id = f.title_id
		WHERE t.title = $1
		ORDER BY f.checkoutyear, f.checkoutmonth, f.fact_id`, title)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	res := []domain.Checkout{}
	for rows.Next() {
		var c domain.Checkout
		if err := rows.Scan(&c.FactID, &c.TitleID, &c.Title, &c.Year, &c.Month, &c.MaterialType, &c.Checkouts); err != nil {
			return nil, err
		}
		res = append(res, c)
	}
	return res, rows.Err()
}

func (r *CheckoutRepo) Insert(ctx context.Context, n domain.NewCheckout) (domain.Checkout, error) {
	var c domain.Checkout
	err := r.pool.QueryRow(ctx, `
		WITH ins AS (
			INSERT INTO checkout_facts (title_id, checkoutyear, checkoutmonth, materialtype, checkouts)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING fact_id, title_id, checkoutyear, checkoutmonth, materialtype, checkouts
		)
		SELECT ins.fact_id, ins.title_id, COALESCE(t.title, ''), ins.checkoutyear, ins.checkoutmonth, ins.materialtype, ins.checkouts
		FROM ins JOIN titles t ON t.title_id = ins.title_id`,
		n.TitleID, n.Year, n.Month, n.MaterialType, n.Checkouts,
	).Scan(&c.FactID, &c.TitleID, &c.Title, &c.Year, &c.Month, &c.MaterialType, &c.Checkouts)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == fkViolation {
			return domain.Checkout{}, domain.ErrTitleNotFound
		}
		return domain.Checkout{}, err
	}
	return c, nil
}

func (r *CheckoutRepo) UpdateCheckouts(ctx context.Context, factID, checkouts int) (domain.Checkout, error) {
	var c domain.Checkout
	err := r.pool.QueryRow(ctx, `
		WITH upd AS (
			UPDATE checkout_facts SET checkouts = $2 WHERE fact_id = $1
			RETURNING fact_id, title_id, checkoutyear, checkoutmonth, materialtype, checkouts
		)
		SELECT upd.fact_id, upd.title_id, COALESCE(t.title, ''), upd.checkoutyear, upd.checkoutmonth, upd.materialtype, upd.checkouts
		FROM upd JOIN titles t ON t.title_id = upd.title_id`,
		factID, checkouts,
	).Scan(&c.FactID, &c.TitleID, &c.Title, &c.Year, &c.Month, &c.MaterialType, &c.Checkouts)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Checkout{}, domain.ErrNotFound
		}
		return domain.Checkout{}, err
	}
	return c, nil
}

func (r *CheckoutRepo) Delete(ctx context.Context, factID int) error {
	tag, err := r.pool.Exec(ctx, `DELETE FROM checkout_facts WHERE fact_id = $1`, factID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrNotFound
	}
	return nil
}
