package main

import (
	"context"
	"flag"
	"fmt"

	"github.com/ItsXomyak/mongodb/internal/conn"
	"go.mongodb.org/mongo-driver/v2/bson"
)

type row struct {
	Title string `bson:"_id"`
	Total int64  `bson:"total"`
}

func main() {
	year := flag.Int("year", 2021, "checkout year")
	flag.Parse()

	ctx := context.Background()
	client, coll := conn.Mongo(ctx)
	defer client.Disconnect(ctx)
	pgConn := conn.Postgres(ctx)
	defer pgConn.Close(ctx)

	pipeline := bson.A{
		bson.M{"$unwind": "$checkouts"},
		bson.M{"$match": bson.M{"checkouts.year": *year}},
		bson.M{"$group": bson.M{"_id": "$title", "total": bson.M{"$sum": "$checkouts.count"}}},
		bson.M{"$sort": bson.D{{Key: "total", Value: -1}, {Key: "_id", Value: 1}}},
		bson.M{"$limit": 5},
	}
	cur, err := coll.Aggregate(ctx, pipeline)
	conn.Must(err)
	var mongoRows []row
	conn.Must(cur.All(ctx, &mongoRows))

	rows, err := pgConn.Query(ctx, `
		SELECT t.title, SUM(f.checkouts)::bigint AS total
		FROM checkout_facts f
		JOIN titles t ON t.title_id = f.title_id
		WHERE f.checkoutyear = $1 AND t.title IS NOT NULL
		GROUP BY t.title
		ORDER BY total DESC, t.title COLLATE "C"
		LIMIT 5`, *year)
	conn.Must(err)
	defer rows.Close()
	var sqlRows []row
	for rows.Next() {
		var r row
		conn.Must(rows.Scan(&r.Title, &r.Total))
		sqlRows = append(sqlRows, r)
	}
	conn.Must(rows.Err())

	fmt.Printf("top-5 titles for %d\n%-4s %-55s %-8s %-8s\n", *year, "#", "title", "mongo", "sql")
	same := len(mongoRows) == len(sqlRows)
	for i := range mongoRows {
		var sqlTotal int64
		var sqlTitle string
		if i < len(sqlRows) {
			sqlTotal, sqlTitle = sqlRows[i].Total, sqlRows[i].Title
		}
		if mongoRows[i] != (row{sqlTitle, sqlTotal}) {
			same = false
		}
		title := mongoRows[i].Title
		if len(title) > 53 {
			title = title[:53] + ".."
		}
		fmt.Printf("%-4d %-55s %-8d %-8d\n", i+1, title, mongoRows[i].Total, sqlTotal)
	}
	fmt.Println("mongo == sql:", same)
}
