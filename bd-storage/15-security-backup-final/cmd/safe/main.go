package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
)

func search(ctx context.Context, conn *pgx.Conn, q string) {
	sql := "SELECT title_id::text, title FROM titles WHERE title LIKE $1 LIMIT 20"
	fmt.Println("SQL:", sql, "| $1 =", "%"+q+"%")
	rows, err := conn.Query(ctx, sql, "%"+q+"%")
	if err != nil {
		fmt.Println("ERROR:", err)
		return
	}
	defer rows.Close()
	n := 0
	for rows.Next() {
		var a, b string
		if err := rows.Scan(&a, &b); err != nil {
			fmt.Println("ERROR:", err)
			return
		}
		fmt.Printf("  %s | %s\n", a, b)
		n++
	}
	if err := rows.Err(); err != nil {
		fmt.Println("ERROR:", err)
	}
	fmt.Println("rows:", n)
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

	inputs := []struct{ name, q string }{
		{"normal", "Love Story"},
		{"a: all rows", "zzzz%' OR 1=1 --"},
		{"b: UNION roles", "zzzz%' UNION SELECT oid::text, rolname FROM pg_roles --"},
		{"c: DROP TABLE", "x%'; DROP TABLE subjects; --"},
	}
	for _, in := range inputs {
		fmt.Printf("\n== %s ==\n", in.name)
		search(ctx, conn, in.q)
	}
}
