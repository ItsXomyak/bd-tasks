# Занятие 8. Web API для БД (Go + Postman)

**Цель:** оформить функции доступа к БД (занятие 7) как HTTP-сервис: CRUD + JSON.
**Стек (вместо Python):** Go, `github.com/gin-gonic/gin` (роутинг `GET /titles/:title`), `github.com/jackc/pgx/v5`, валидация через binding-теги gin (`go-playground/validator`).

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
1. `main.go`: `gin.Default()`, пул pgx, запуск на `127.0.0.1:8000`. Вместо `/docs` — Postman-коллекция (опц.: swaggo/swag для Swagger UI).
2. `GET /titles/top?year=&limit=` — `year` обязателен (иначе 422), `limit` 1..100, по умолчанию 10.
3. `GET /titles/{title}` — выдачи по названию; пусто → 404 с JSON `{"error":"..."}`.
4. `POST /checkouts` — тело `{title_id, year, month 1–12, material_type, checkouts ≥ 0}` → struct + `Validate()`. Успех 201, неверные данные 422.
5. `PUT /checkouts` — изменить число выдач (200); `DELETE /checkouts` — удалить (200/204). Нет записи → 404.
6. Postman: коллекция из 8 запросов (успешные + `month=13`, несуществующий `title_id`, повторное удаление) с ответами 200/201/404/422.

## Подсказки (Go-версия)
- В gin ≥1.8 статический `/titles/top` и параметрический `/titles/:title` сосуществуют, статика приоритетнее — порядок регистрации не важен (в отличие от FastAPI). Проверить на вашей версии gin и отметить в отчёте.
- FK-ошибка: `errors.As(err, &pgErr)` и `pgErr.Code == "23503"` → 404, не 500.
- Ответы: `c.JSON(status, obj)`; ошибки единым форматом `c.AbortWithStatusJSON(status, gin.H{"error": msg})`.
- Тело запроса: `c.ShouldBindJSON(&req)` + теги `binding:"required,min=1,max=12"` (month), `binding:"gte=0"` (checkouts); ошибка биндинга → 422 (по умолчанию gin не даёт 422, ставить вручную).
- Query: `c.ShouldBindQuery(&q)` для `year` (required) и `limit` (`min=1,max=100`, default 10).

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
