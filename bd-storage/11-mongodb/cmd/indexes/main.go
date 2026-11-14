package main

import (
	"context"
	"fmt"

	"github.com/ItsXomyak/mongodb/internal/conn"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

func main() {
	ctx := context.Background()
	client, coll := conn.Mongo(ctx)
	defer client.Disconnect(ctx)

	_, err := coll.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "title", Value: 1}}},
		{Keys: bson.D{{Key: "subjects", Value: 1}}},
	})
	conn.Must(err)

	cur, err := coll.Indexes().List(ctx)
	conn.Must(err)
	var idx []bson.M
	conn.Must(cur.All(ctx, &idx))
	for _, i := range idx {
		fmt.Printf("index %-14v key=%v\n", i["name"], i["key"])
	}

	explain := coll.Database().RunCommand(ctx, bson.D{
		{Key: "explain", Value: bson.D{
			{Key: "find", Value: conn.CollectionName},
			{Key: "filter", Value: bson.M{"subjects": "Fiction"}},
		}},
		{Key: "verbosity", Value: "queryPlanner"},
	})
	var plan bson.Raw
	conn.Must(explain.Decode(&plan))
	stage := plan.Lookup("queryPlanner", "winningPlan", "stage").StringValue()
	input := plan.Lookup("queryPlanner", "winningPlan", "inputStage", "stage").StringValue()
	fmt.Println("find subjects=Fiction, winning plan:", stage, "->", input)
}
