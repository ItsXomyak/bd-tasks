package app

import (
	"context"
	"log"

	httpadapter "github.com/ItsXomyak/api-integration/internal/adapter/http"
	"github.com/ItsXomyak/api-integration/internal/adapter/postgres"
	"github.com/ItsXomyak/api-integration/internal/config"
	"github.com/ItsXomyak/api-integration/internal/service"
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
	router := httpadapter.NewRouter(httpadapter.NewHandler(svc), cfg.APIKey)

	if err := router.Run(cfg.Addr); err != nil {
		log.Fatal("server: ", err)
	}
}
