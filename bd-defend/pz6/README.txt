docker compose up -d                                  # поднять
docker compose exec db psql -U postgres               # зайти в psql
docker compose exec db psql -U postgres -f /checks.sql  # прогнать проверки
docker compose down                                   # выключить (данные сохраняются)
docker compose down -v                                # выключить и стереть БД (setup.sql прогонится заново)