package app

import (
	"context"
	"log"

	httpadapter "github.com/ItsXomyak/web-api/internal/adapter/http"
	"github.com/ItsXomyak/web-api/internal/adapter/postgres"
	"github.com/ItsXomyak/web-api/internal/config"
	"github.com/ItsXomyak/web-api/internal/service"
)

func Run() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("config: ", err)
	}

	repo, err := postgres.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatal("db: ", err)
	}
	defer repo.Close()

	svc := service.NewCheckoutService(repo)
	router := httpadapter.NewRouter(httpadapter.NewHandler(svc))

	if err := router.Run(cfg.Addr); err != nil {
		log.Fatal("server: ", err)
	}
}
