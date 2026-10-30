docker compose up -d                                    # поднять (setup.sh кладёт сертификат в PGDATA и правит pg_hba.conf, setup.sql включает ssl)
docker compose exec db psql -U postgres -d university   # зайти в psql
docker compose exec db psql -U postgres -d university -f /checks.sql   # прогнать все проверки
docker compose down                                     # выключить
docker compose down -v                                  # выключить и стереть БД

certs/server.crt, certs/server.key — самоподписанный сертификат CN=localhost (только для демо):
openssl req -new -x509 -days 3650 -nodes -newkey rsa:2048 -subj "/CN=localhost" -keyout certs/server.key -out certs/server.crt
