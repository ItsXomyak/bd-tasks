package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
)

const (
	rowsCount = 100_000
	idOffset  = 10_000_000
)

var columns = []string{"id", "materialtype", "checkoutyear", "checkoutmonth", "checkouts", "title"}

func generate() [][]any {
	out := make([][]any, rowsCount)
	for i := range out {
		n := idOffset + i
		out[i] = []any{n, "SOUNDDISC", 2010 + n%14, 1 + n%12, n % 50, fmt.Sprintf("Love story number %d", n)}
	}
	return out
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close(ctx)

	for _, table := range []string{"bench_noidx", "bench_idx"} {
		data := generate()
		start := time.Now()
		if _, err := conn.CopyFrom(ctx, pgx.Identifier{table}, columns, pgx.CopyFromRows(data)); err != nil {
			log.Fatal(table, ": ", err)
		}
		fmt.Printf("%-12s %d rows: %v\n", table, rowsCount, time.Since(start).Round(time.Millisecond))
	}
}
