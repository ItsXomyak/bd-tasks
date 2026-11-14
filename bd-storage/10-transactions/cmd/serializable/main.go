package main

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"github.com/ItsXomyak/transactions/internal/pg"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	titleID    = 4
	workers    = 10
	start      = 100
	maxRetries = 50
)

func decrement(ctx context.Context, pool *pgxpool.Pool, retries *atomic.Int64) error {
	for attempt := 0; attempt < maxRetries; attempt++ {
		err := tryOnce(ctx, pool)
		if err == nil {
			return nil
		}
		if pg.Code(err) != pg.SerializationFailure {
			return err
		}
		retries.Add(1)
		time.Sleep(time.Duration(attempt+1) * 2 * time.Millisecond)
	}
	return fmt.Errorf("gave up after %d retries", maxRetries)
}

func tryOnce(ctx context.Context, pool *pgxpool.Pool) error {
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead})
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	v := pg.Available(ctx, tx, titleID)
	time.Sleep(5 * time.Millisecond)
	if _, err := tx.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, v-1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func main() {
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(pg.DSN())
	pg.Must(err)
	cfg.MaxConns = workers
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	pg.Must(err)
	defer pool.Close()

	_, err = pool.Exec(ctx, `UPDATE copies SET available = $2 WHERE title_id = $1`, titleID, start)
	pg.Must(err)

	var retries atomic.Int64
	var failed atomic.Int64
	var wg sync.WaitGroup
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := decrement(ctx, pool, &retries); err != nil {
				failed.Add(1)
				fmt.Println("worker error:", err)
			}
		}()
	}
	wg.Wait()

	var final int
	pg.Must(pool.QueryRow(ctx, `SELECT available FROM copies WHERE title_id = $1`, titleID).Scan(&final))
	fmt.Printf("repeatable read: workers=%d expected=%d actual=%d serialization retries=%d failed=%d\n",
		workers, start-workers, final, retries.Load(), failed.Load())
}
