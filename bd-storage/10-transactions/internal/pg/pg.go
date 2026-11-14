package pg

import (
	"context"
	"errors"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

const (
	SerializationFailure = "40001"
	DeadlockDetected     = "40P01"
	NotNullViolation     = "23502"
)

func DSN() string {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is not set")
	}
	return dsn
}

func Connect(ctx context.Context) *pgx.Conn {
	conn, err := pgx.Connect(ctx, DSN())
	if err != nil {
		log.Fatal(err)
	}
	return conn
}

func Code(err error) string {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code
	}
	return ""
}

func Must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func Reset(ctx context.Context, conn *pgx.Conn, titleID, available int) {
	_, err := conn.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, available)
	Must(err)
}

func Available(ctx context.Context, q interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}, titleID int) int {
	var n int
	Must(q.QueryRow(ctx, `SELECT available FROM copies WHERE title_id = $1`, titleID).Scan(&n))
	return n
}
