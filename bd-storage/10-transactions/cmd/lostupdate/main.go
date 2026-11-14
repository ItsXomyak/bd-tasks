package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/ItsXomyak/transactions/internal/pg"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	titleID = 3
	workers = 50
	start   = 100
)

func naive(ctx context.Context, pool *pgxpool.Pool) error {
	var v int
	if err := pool.QueryRow(ctx, `SELECT available FROM copies WHERE title_id = $1`, titleID).Scan(&v); err != nil {
		return err
	}
	time.Sleep(5 * time.Millisecond)
	_, err := pool.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, v-1)
	return err
}

func atomic(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `UPDATE copies SET available = available - 1 WHERE title_id = $1`, titleID)
	return err
}

func forUpdate(ctx context.Context, pool *pgxpool.Pool) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var v int
	if err := tx.QueryRow(ctx, `SELECT available FROM copies WHERE title_id = $1 FOR UPDATE`, titleID).Scan(&v); err != nil {
		return err
	}
	time.Sleep(5 * time.Millisecond)
	if _, err := tx.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, v-1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func run(ctx context.Context, pool *pgxpool.Pool, name string, op func(context.Context, *pgxpool.Pool) error) {
	_, err := pool.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, start)
	pg.Must(err)

	var wg sync.WaitGroup
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := op(ctx, pool); err != nil {
				log.Println(name, "worker error:", err)
			}
		}()
	}
	wg.Wait()

	var final int
	pg.Must(pool.QueryRow(ctx, `SELECT available FROM copies WHERE title_id = $1`, titleID).Scan(&final))
	expected := start - workers
	fmt.Printf("%-10s expected=%d actual=%d lost=%d\n", name, expected, final, final-expected)
}

func main() {
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(pg.DSN())
	pg.Must(err)
	cfg.MaxConns = workers
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	pg.Must(err)
	defer pool.Close()

	modes := map[string]func(context.Context, *pgxpool.Pool) error{
		"naive":     naive,
		"atomic":    atomic,
		"forupdate": forUpdate,
	}

	if len(os.Args) > 1 {
		op, ok := modes[os.Args[1]]
		if !ok {
			log.Fatal("mode must be naive, atomic or forupdate")
		}
		run(ctx, pool, os.Args[1], op)
		return
	}
	for _, name := range []string{"naive", "atomic", "forupdate"} {
		run(ctx, pool, name, modes[name])
	}
}
