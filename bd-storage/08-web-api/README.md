# Занятие 8. Web API для БД (Go + Postman)

**Цель:** оформить функции доступа к БД (занятие 7) как HTTP-сервис: CRUD + JSON.
**Стек (вместо Python):** Go 1.22+, `net/http` (ServeMux с паттернами `GET /titles/{title}`), `github.com/jackc/pgx/v5`, валидация вручную (или `go-playground/validator`).

## Структура
```
08-web-api/
  go.mod
  cmd/api/main.go      # запуск, роутинг
  internal/db/db.go    # функции доступа из занятия 7 (pgxpool)
  internal/api/        # handlers, модели, ошибки
  postman/collection.json
```
DSN — только из env: `DATABASE_URL`.

## Задания
1. `main.go`: `http.NewServeMux()`, пул pgx, запуск на `127.0.0.1:8000`. Вместо `/docs` — Postman-коллекция (опц.: swaggo/swag для Swagger UI).
2. `GET /titles/top?year=&limit=` — `year` обязателен (иначе 422), `limit` 1..100, по умолчанию 10.
3. `GET /titles/{title}` — выдачи по названию; пусто → 404 с JSON `{"error":"..."}`.
4. `POST /checkouts` — тело `{title_id, year, month 1–12, material_type, checkouts ≥ 0}` → struct + `Validate()`. Успех 201, неверные данные 422.
5. `PUT /checkouts` — изменить число выдач (200); `DELETE /checkouts` — удалить (200/204). Нет записи → 404.
6. Postman: коллекция из 8 запросов (успешные + `month=13`, несуществующий `title_id`, повторное удаление) с ответами 200/201/404/422.

## Подсказки (Go-версия)
- В Go 1.22 `/titles/top` (точный путь) приоритетнее `/titles/{title}` — проверить: что будет при обратном порядке регистрации (в Go порядок не важен, в отличие от FastAPI; отметить в отчёте).
- FK-ошибка: `errors.As(err, &pgErr)` и `pgErr.Code == "23503"` → 404, не 500.
- Единый хелпер `writeJSON(w, status, v)` и `writeErr(w, status, msg)`.
- Ловить `json.Decoder.DisallowUnknownFields()` → 422/400.

## Что показать
5 работающих маршрутов + коллекция Postman с ответами 200/201/404/422.

## Критерии (100)
| Критерий | Баллы |
|---|---|
| GET-маршруты (топ + поиск), проверка параметров | 25 |
| POST/PUT/DELETE с кодами 201/200/404 | 30 |
| Валидация модели, 422 на неверные данные | 15 |
| Postman (8 запросов, включая ошибочные) | 20 |
| Устно: 404 vs 422 vs 500 | 10 |

## Чек-лист
- [ ] `go run ./cmd/api` стартует
- [ ] 5 маршрутов отвечают
- [ ] FK → 404
- [ ] Postman экспортирован в `postman/`
