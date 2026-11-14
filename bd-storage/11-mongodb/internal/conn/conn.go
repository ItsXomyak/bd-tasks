package conn

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const (
	DatabaseName   = "seattle_mongo"
	CollectionName = "titles"
	defaultURI     = "mongodb://localhost:27017"
)

func Must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func Postgres(ctx context.Context) *pgx.Conn {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is not set")
	}
	c, err := pgx.Connect(ctx, dsn)
	Must(err)
	return c
}

func Mongo(ctx context.Context) (*mongo.Client, *mongo.Collection) {
	uri := os.Getenv("MONGO_URI")
	if uri == "" {
		uri = defaultURI
	}
	client, err := mongo.Connect(options.Client().ApplyURI(uri))
	Must(err)
	Must(client.Ping(ctx, nil))
	return client, client.Database(DatabaseName).Collection(CollectionName)
}
