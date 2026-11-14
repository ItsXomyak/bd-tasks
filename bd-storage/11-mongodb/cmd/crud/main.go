package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/mongodb/internal/conn"
	"github.com/ItsXomyak/mongodb/internal/doc"
	"go.mongodb.org/mongo-driver/v2/bson"
)

const testTitle = "ZZZ test title"

func main() {
	ctx := context.Background()
	client, coll := conn.Mongo(ctx)
	defer client.Disconnect(ctx)

	_, err := coll.DeleteMany(ctx, bson.M{"title": testTitle})
	conn.Must(err)

	filter := bson.M{
		"subjects":  "Fiction",
		"checkouts": bson.M{"$elemMatch": bson.M{"year": 2021, "count": bson.M{"$gte": 5}}},
	}
	found, err := coll.CountDocuments(ctx, filter)
	conn.Must(err)
	fmt.Printf("1. find subjects=Fiction and checkout in 2021 with count>=5: %d documents\n", found)

	_, err = coll.InsertOne(ctx, doc.Title{
		Title:     testTitle,
		Creator:   "Test Author",
		Subjects:  []string{"Fiction", "Testing"},
		Checkouts: []doc.Checkout{{Year: 2021, Month: 7, MaterialType: "SOUNDDISC", Count: 1}},
	})
	conn.Must(err)
	fmt.Println("2. insert: document created")

	res, err := coll.UpdateOne(ctx, bson.M{"title": testTitle},
		bson.M{"$push": bson.M{"checkouts": doc.Checkout{Year: 2021, Month: 8, MaterialType: "SOUNDDISC", Count: 5}}})
	conn.Must(err)
	var afterPush doc.Title
	conn.Must(coll.FindOne(ctx, bson.M{"title": testTitle}).Decode(&afterPush))
	fmt.Printf("3. $push: matched=%d modified=%d, checkouts array length=%d\n", res.MatchedCount, res.ModifiedCount, len(afterPush.Checkouts))

	res, err = coll.UpdateOne(ctx, bson.M{"title": testTitle}, bson.M{"$set": bson.M{"creator": "Changed Author"}})
	conn.Must(err)
	var afterSet doc.Title
	conn.Must(coll.FindOne(ctx, bson.M{"title": testTitle}).Decode(&afterSet))
	fmt.Printf("4. $set: matched=%d modified=%d, creator=%q\n", res.MatchedCount, res.ModifiedCount, afterSet.Creator)

	del, err := coll.DeleteOne(ctx, bson.M{"title": testTitle})
	conn.Must(err)
	left, err := coll.CountDocuments(ctx, bson.M{"title": testTitle})
	conn.Must(err)
	fmt.Printf("5. delete: deleted=%d, left=%d\n", del.DeletedCount, left)
}
