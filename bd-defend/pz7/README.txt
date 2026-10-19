docker compose up -d                                    # поднять БД (setup.sql выполнится сам)
docker compose exec db psql -U postgres -d university   # psql

python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

export DATABASE_URL="postgresql://app_user:App_Strong_123!@localhost:54327/university"

python3 unsafe_query.py            # этап 2: только печатает текст запроса
.venv/bin/python safe_query.py     # этап 3-4: параметризованный запрос + проверка формата
.venv/bin/python safe_query_noval.py   # этап 3 без проверки: апостроф уходит как параметр

docker compose down                                     # выключить
docker compose down -v                                  # стереть БД
