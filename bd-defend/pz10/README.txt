docker compose up -d                                    # поднять (setup.sql создаст university_backup с данными)
docker compose exec db psql -U postgres -f /checks.sql  # дамп, восстановление, проверки (копии ложатся в ./backups)
docker compose exec db psql -U postgres -d university_restore   # зайти в восстановленную базу
docker compose down                                     # выключить
docker compose down -v                                  # выключить и стереть БД
