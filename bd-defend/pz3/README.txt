docker compose up -d                                    # поднять (setup.sql выполнится сам при первом старте)
docker compose exec db psql -U postgres -d university   # зайти в psql
docker compose exec db psql -U postgres -d university -f /checks.sql   # прогнать все проверки
docker compose down                                     # выключить
docker compose down -v                                  # выключить и стереть БД
