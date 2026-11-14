package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/transactions/internal/pg"
	"github.com/jackc/pgx/v5"
)

const titleID = 7

func show(ctx context.Context, q interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}, label string) {
	var xmin, xmax uint32
	var ctid string
	var available int
	pg.Must(q.QueryRow(ctx,
		`SELECT xmin::text::bigint, xmax::text::bigint, ctid::text, available FROM copies WHERE title_id = $1`, titleID,
	).Scan(&xmin, &xmax, &ctid, &available))
	fmt.Printf("%-28s xmin=%d xmax=%d ctid=%s available=%d\n", label, xmin, xmax, ctid, available)
}

func main() {
	ctx := context.Background()
	conn := pg.Connect(ctx)
	defer conn.Close(ctx)

	pg.Reset(ctx, conn, titleID, 100)
	show(ctx, conn, "before update:")

	pg.Reset(ctx, conn, titleID, 99)
	show(ctx, conn, "after update:")

	tx, err := conn.Begin(ctx)
	pg.Must(err)
	_, err = tx.Exec(ctx, `UPDATE copies SET available = 98 WHERE title_id = $1`, titleID)
	pg.Must(err)
	show(ctx, tx, "inside tx after 2nd update:")

	other := pg.Connect(ctx)
	defer other.Close(ctx)
	show(ctx, other, "other session (not committed):")

	pg.Must(tx.Rollback(ctx))
	show(ctx, conn, "after rollback:")
}
