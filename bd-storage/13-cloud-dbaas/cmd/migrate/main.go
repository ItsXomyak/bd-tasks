package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/ItsXomyak/cloud/internal/schema"
	"github.com/jackc/pgx/v5"
)

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

func count(ctx context.Context, conn *pgx.Conn, table string) int {
	var n int
	if err := conn.QueryRow(ctx, "SELECT count(*) FROM "+table).Scan(&n); err != nil {
		log.Fatal(err)
	}
	return n
}

func tableExists(ctx context.Context, conn *pgx.Conn, table string) bool {
	var ok bool
	err := conn.QueryRow(ctx, `SELECT to_regclass($1) IS NOT NULL`, table).Scan(&ok)
	if err != nil {
		log.Fatal(err)
	}
	return ok
}

func prepare(ctx context.Context, cloud *pgx.Conn, recreate bool) {
	for _, t := range schema.Tables {
		if tableExists(ctx, cloud, t.Name) && !recreate {
			log.Fatalf("table %s already exists in the cloud database; rerun with -recreate to drop and recreate", t.Name)
		}
	}
	for _, name := range schema.DropOrder {
		if _, err := cloud.Exec(ctx, "DROP TABLE IF EXISTS "+name+" CASCADE"); err != nil {
			log.Fatal(err)
		}
	}
	if _, err := cloud.Exec(ctx, schema.DDL); err != nil {
		log.Fatal(err)
	}
}

func copyTable(ctx context.Context, local, cloud *pgx.Conn, t schema.Table) {
	pr, pw := io.Pipe()
	errCh := make(chan error, 1)
	go func() {
		_, err := local.PgConn().CopyTo(ctx, pw, fmt.Sprintf("COPY (SELECT %s FROM %s) TO STDOUT", t.Columns, t.Name))
		pw.CloseWithError(err)
		errCh <- err
	}()

	_, err := cloud.PgConn().CopyFrom(ctx, pr, fmt.Sprintf("COPY %s (%s) FROM STDIN", t.Name, t.Columns))
	if err != nil {
		pr.CloseWithError(err)
		log.Fatalf("copy %s: %v", t.Name, err)
	}
	if err := <-errCh; err != nil {
		log.Fatalf("read %s: %v", t.Name, err)
	}

	if t.Serial != "" {
		_, err := cloud.Exec(ctx, fmt.Sprintf(
			`SELECT setval(pg_get_serial_sequence('%s', '%s'), COALESCE((SELECT max(%s) FROM %s), 1))`,
			t.Name, t.Serial, t.Serial, t.Name))
		if err != nil {
			log.Fatal(err)
		}
	}
}

func main() {
	recreate := flag.Bool("recreate", false, "drop and recreate tables in the cloud database")
	flag.Parse()

	ctx := context.Background()
	local := connect(ctx, "LOCAL_DSN")
	defer local.Close(ctx)
	cloud := connect(ctx, "CLOUD_DSN")
	defer cloud.Close(ctx)

	prepare(ctx, cloud, *recreate)
	for _, t := range schema.Tables {
		copyTable(ctx, local, cloud, t)
	}

	fmt.Printf("%-16s %10s %10s %s\n", "table", "local", "cloud", "match")
	allMatch := true
	for _, t := range schema.Tables {
		l, c := count(ctx, local, t.Name), count(ctx, cloud, t.Name)
		fmt.Printf("%-16s %10d %10d %v\n", t.Name, l, c, l == c)
		allMatch = allMatch && l == c
	}
	if !allMatch {
		os.Exit(1)
	}
}
