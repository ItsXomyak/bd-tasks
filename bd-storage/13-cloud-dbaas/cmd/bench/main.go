package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"slices"
	"time"

	"github.com/jackc/pgx/v5"
)

const query = `
SELECT t.title, SUM(f.checkouts)::bigint AS total
FROM checkout_facts f
JOIN titles t ON t.title_id = f.title_id
WHERE f.checkoutyear = $1 AND t.title IS NOT NULL
GROUP BY t.title
ORDER BY total DESC, t.title
LIMIT 10`

func connect(ctx context.Context, envName string) *pgx.Conn {
	dsn := os.Getenv(envName)
	if dsn == "" {
		log.Fatalf("%s is not set", envName)
	}
	conn, err := pgx.Connect(ctx, dsn)
	if err != nil {
		log.Fatalf("%s: cannot connect", envName)
	}
	return conn
}

func run(ctx context.Context, conn *pgx.Conn, year int) (int, time.Duration) {
	start := time.Now()
	rows, err := conn.Query(ctx, query, year)
	if err != nil {
		log.Fatal(err)
	}
	n := 0
	for rows.Next() {
		n++
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}
	return n, time.Since(start)
}

func median(conn *pgx.Conn, ctx context.Context, year, runs int) (int, time.Duration) {
	run(ctx, conn, year)
	times := make([]time.Duration, runs)
	var rows int
	for i := range times {
		rows, times[i] = run(ctx, conn, year)
	}
	slices.Sort(times)
	return rows, times[len(times)/2]
}

func main() {
	year := flag.Int("year", 2021, "checkout year")
	runs := flag.Int("runs", 21, "number of measured runs")
	flag.Parse()

	ctx := context.Background()
	local := connect(ctx, "LOCAL_DSN")
	defer local.Close(ctx)
	cloud := connect(ctx, "CLOUD_DSN")
	defer cloud.Close(ctx)

	lr, lm := median(local, ctx, *year, *runs)
	cr, cm := median(cloud, ctx, *year, *runs)

	fmt.Printf("query: top-10 titles for %d, %d runs, median\n", *year, *runs)
	fmt.Printf("local: %d rows, %v\n", lr, lm.Round(10*time.Microsecond))
	fmt.Printf("cloud: %d rows, %v\n", cr, cm.Round(10*time.Microsecond))
	fmt.Printf("row counts equal: %v\n", lr == cr)
}
