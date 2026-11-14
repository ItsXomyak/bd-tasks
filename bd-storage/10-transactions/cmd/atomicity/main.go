package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/transactions/internal/pg"
)

func main() {
	ctx := context.Background()
	a := pg.Connect(ctx)
	b := pg.Connect(ctx)
	defer a.Close(ctx)
	defer b.Close(ctx)

	const titleID = 1
	pg.Reset(ctx, a, titleID, 100)

	var loansBefore int
	pg.Must(b.QueryRow(ctx, `SELECT count(*) FROM loans`).Scan(&loansBefore))
	fmt.Printf("before: available=%d loans=%d\n", pg.Available(ctx, b, titleID), loansBefore)

	tx, err := a.Begin(ctx)
	pg.Must(err)
	_, err = tx.Exec(ctx, `UPDATE copies SET available = available - 1 WHERE title_id = $1`, titleID)
	pg.Must(err)
	fmt.Printf("session A inside tx: available=%d\n", pg.Available(ctx, tx, titleID))
	fmt.Printf("session B before commit: available=%d (changes are invisible)\n", pg.Available(ctx, b, titleID))

	_, err = tx.Exec(ctx, `INSERT INTO loans (title_id, reader) VALUES ($1, NULL)`, titleID)
	fmt.Printf("insert with reader=NULL: error=%v code=%s\n", err, pg.Code(err))

	pg.Must(tx.Rollback(ctx))

	var loansAfter int
	pg.Must(b.QueryRow(ctx, `SELECT count(*) FROM loans`).Scan(&loansAfter))
	fmt.Printf("after rollback: available=%d loans=%d (both changes undone)\n", pg.Available(ctx, b, titleID), loansAfter)
}
