package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/mongodb/internal/conn"
	"github.com/ItsXomyak/mongodb/internal/doc"
)

const query = `
SELECT t.title,
       COALESCE(t.creator, ''),
       COALESCE(t.publisher, ''),
       f.fact_id,
       COALESCE(f.checkoutyear, 0),
       COALESCE(f.checkoutmonth, 0),
       COALESCE(f.materialtype, ''),
       COALESCE(f.checkouts, 0),
       COALESCE(s.subject_name, '')
FROM titles t
LEFT JOIN checkout_facts f ON f.title_id = t.title_id
LEFT JOIN title_subjects ts ON ts.title_id = t.title_id
LEFT JOIN subjects s ON s.subject_id = ts.subject_id
WHERE t.title IS NOT NULL
ORDER BY t.title, f.fact_id`

type builder struct {
	doc      *doc.Title
	facts    map[int]bool
	subjects map[string]bool
}

func main() {
	ctx := context.Background()
	pgConn := conn.Postgres(ctx)
	defer pgConn.Close(ctx)
	client, coll := conn.Mongo(ctx)
	defer client.Disconnect(ctx)

	rows, err := pgConn.Query(ctx, query)
	conn.Must(err)
	defer rows.Close()

	builders := map[string]*builder{}
	var order []string
	for rows.Next() {
		var title, creator, publisher, material, subject string
		var factID *int
		var year, month, count int
		conn.Must(rows.Scan(&title, &creator, &publisher, &factID, &year, &month, &material, &count, &subject))

		b, ok := builders[title]
		if !ok {
			b = &builder{
				doc:      &doc.Title{Title: title, Creator: creator, Publisher: publisher, Subjects: []string{}, Checkouts: []doc.Checkout{}},
				facts:    map[int]bool{},
				subjects: map[string]bool{},
			}
			builders[title] = b
			order = append(order, title)
		}
		if b.doc.Creator == "" {
			b.doc.Creator = creator
		}
		if b.doc.Publisher == "" {
			b.doc.Publisher = publisher
		}
		if factID != nil && !b.facts[*factID] {
			b.facts[*factID] = true
			b.doc.Checkouts = append(b.doc.Checkouts, doc.Checkout{Year: year, Month: month, MaterialType: material, Count: count})
		}
		if subject != "" && !b.subjects[subject] {
			b.subjects[subject] = true
			b.doc.Subjects = append(b.doc.Subjects, subject)
		}
	}
	conn.Must(rows.Err())

	docs := make([]any, 0, len(order))
	for _, t := range order {
		docs = append(docs, builders[t].doc)
	}

	_, err = coll.DeleteMany(ctx, map[string]any{})
	conn.Must(err)
	res, err := coll.InsertMany(ctx, docs)
	conn.Must(err)

	var sqlTitles, sqlFacts int
	conn.Must(pgConn.QueryRow(ctx, `SELECT count(DISTINCT title) FROM titles`).Scan(&sqlTitles))
	conn.Must(pgConn.QueryRow(ctx, `SELECT count(*) FROM checkout_facts f JOIN titles t USING (title_id) WHERE t.title IS NOT NULL`).Scan(&sqlFacts))

	mongoFacts := 0
	for _, t := range order {
		mongoFacts += len(builders[t].doc.Checkouts)
	}
	fmt.Printf("inserted documents: %d, distinct titles in SQL: %d, match=%v\n", len(res.InsertedIDs), sqlTitles, len(res.InsertedIDs) == sqlTitles)
	fmt.Printf("embedded checkouts: %d, checkout_facts in SQL: %d, match=%v\n", mongoFacts, sqlFacts, mongoFacts == sqlFacts)
}
