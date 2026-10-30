# Занятие 11. MongoDB в Web-приложении

**Цель:** перенести данные в документную модель, выполнить CRUD и агрегацию.
**Стек (вместо pymongo):** Go + `go.mongodb.org/mongo-driver/v2` (`mongo`, `bson`) + `pgx` для чтения из PostgreSQL.

## Структура
```
11-mongodb/
  go.mod
  cmd/load/main.go     # PG -> документы -> insert_many
  cmd/crud/main.go     # 5 операций CRUD
  cmd/agg/main.go      # агрегация top-5 + сверка с SQL
  cmd/indexes/main.go  # создание и вывод индексов
  COMPARE.md           # SQL vs MongoDB (4–5 предложений)
```
URI: env `MONGO_URI` (по умолчанию `mongodb://localhost:27017`), БД `seattle_mongo`, коллекция `titles`.

## Задания
1. **Загрузка:** один SQL-запрос с JOIN → группировка в Go (`map[titleID]*TitleDoc`) → `InsertMany`. Документ:
   `{title, creator, publisher, subjects: [..], checkouts: [{year, month, material_type, count}]}`.
   Перед загрузкой — `DeleteMany({})`. Число документов == `COUNT(DISTINCT title)` в SQL.
2. **CRUD (5 операций):** найти по `subjects` + условию на год; вставить документ; `$push` выдачи в массив; `$set` поля; удалить документ.
3. **Агрегация:** `$unwind → $match → $group → $sort → $limit 5` за год. Результат совпадает с SQL из занятия 7.
4. **Индексы:** по `title` и `subjects` (`Indexes().CreateMany`), вывести через `Indexes().List` / Compass.
5. **Письменно:** что удобнее в SQL, что в MongoDB (JOIN, транзакции, вложенные массивы).

## Критерии (100)
| Критерий | Баллы |
|---|---|
| Преобразование и загрузка (число совпадает с SQL) | 25 |
| CRUD: 5 операций | 25 |
| Агрегация = SQL | 25 |
| Индексы | 10 |
| Сравнение SQL / MongoDB | 15 |
