package config

import (
	"errors"
	"os"

	"github.com/joho/godotenv"
)

const defaultAddr = "127.0.0.1:8000"

type Config struct {
	DatabaseURL string
	Addr        string
}

func Load() (Config, error) {
	_ = godotenv.Load()

	cfg := Config{
		DatabaseURL: os.Getenv("DATABASE_URL"),
		Addr:        os.Getenv("ADDR"),
	}
	if cfg.DatabaseURL == "" {
		return Config{}, errors.New("DATABASE_URL is not set")
	}
	if cfg.Addr == "" {
		cfg.Addr = defaultAddr
	}
	return cfg, nil
}
