package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/transactions/internal/pg"
	"github.com/jackc/pgx/v5"
)

const titleID = 2

func nonRepeatable(ctx context.Context, level pgx.TxIsoLevel) {
	s1 := pg.Connect(ctx)
	s2 := pg.Connect(ctx)
	defer s1.Close(ctx)
	defer s2.Close(ctx)

	pg.Reset(ctx, s1, titleID, 10)

	tx, err := s1.BeginTx(ctx, pgx.TxOptions{IsoLevel: level})
	pg.Must(err)
	first := pg.Available(ctx, tx, titleID)

	_, err = s2.Exec(ctx, `UPDATE copies SET available = 7 WHERE title_id = $1`, titleID)
	pg.Must(err)

	second := pg.Available(ctx, tx, titleID)
	pg.Must(tx.Commit(ctx))
	fmt.Printf("%-16s first read=%d, second read (after S2 commit)=%d\n", level, first, second)
}

func dirtyRead(ctx context.Context, level pgx.TxIsoLevel) {
	s1 := pg.Connect(ctx)
	s2 := pg.Connect(ctx)
	defer s1.Close(ctx)
	defer s2.Close(ctx)

	pg.Reset(ctx, s1, titleID, 10)

	writer, err := s2.Begin(ctx)
	pg.Must(err)
	_, err = writer.Exec(ctx, `UPDATE copies SET available = 999 WHERE title_id = $1`, titleID)
	pg.Must(err)

	reader, err := s1.BeginTx(ctx, pgx.TxOptions{IsoLevel: level})
	pg.Must(err)
	seen := pg.Available(ctx, reader, titleID)
	pg.Must(reader.Commit(ctx))
	pg.Must(writer.Rollback(ctx))

	fmt.Printf("%-16s reads uncommitted 999? sees=%d dirty=%v\n", level, seen, seen == 999)
}

func main() {
	ctx := context.Background()
	fmt.Println("non-repeatable read:")
	nonRepeatable(ctx, pgx.ReadCommitted)
	nonRepeatable(ctx, pgx.RepeatableRead)
	fmt.Println("dirty read:")
	dirtyRead(ctx, pgx.ReadUncommitted)
	dirtyRead(ctx, pgx.ReadCommitted)
}
