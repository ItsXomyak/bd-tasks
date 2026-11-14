package main

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/ItsXomyak/transactions/internal/pg"
	"github.com/jackc/pgx/v5"
)

func update(ctx context.Context, tx pgx.Tx, titleID int) error {
	_, err := tx.Exec(ctx, `UPDATE copies SET available = available - 1 WHERE title_id = $1`, titleID)
	return err
}

func worker(ctx context.Context, name string, first, second int, wg *sync.WaitGroup) {
	defer wg.Done()
	conn := pg.Connect(ctx)
	defer conn.Close(ctx)

	tx, err := conn.Begin(ctx)
	pg.Must(err)
	defer tx.Rollback(ctx)

	pg.Must(update(ctx, tx, first))
	time.Sleep(300 * time.Millisecond)

	if err := update(ctx, tx, second); err != nil {
		fmt.Printf("%s: rows %d then %d -> error code=%s: %v\n", name, first, second, pg.Code(err), err)
		return
	}
	pg.Must(tx.Commit(ctx))
	fmt.Printf("%s: rows %d then %d -> committed\n", name, first, second)
}

func scenario(ctx context.Context, title string, aFirst, aSecond, bFirst, bSecond int) {
	fmt.Println(title)
	var wg sync.WaitGroup
	wg.Add(2)
	go worker(ctx, "A", aFirst, aSecond, &wg)
	go worker(ctx, "B", bFirst, bSecond, &wg)
	wg.Wait()
}

func main() {
	ctx := context.Background()
	conn := pg.Connect(ctx)
	pg.Reset(ctx, conn, 5, 100)
	pg.Reset(ctx, conn, 6, 100)
	conn.Close(ctx)

	scenario(ctx, "different order (deadlock):", 5, 6, 6, 5)
	scenario(ctx, "same order (fix):", 5, 6, 5, 6)
}
