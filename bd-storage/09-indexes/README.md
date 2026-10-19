# Занятие 9. Индексы и планы выполнения

**Цель:** по `EXPLAIN (ANALYZE, BUFFERS)` увидеть, когда индекс помогает, когда нет и сколько стоит.
**Go:** только для замера вставки 100 000 строк (п.6) — `cmd/insertbench/main.go` на pgx (`CopyFrom`/batch). Остальное — SQL в psql.

## Структура
```
09-indexes/
  sql/01_big_table.sql   # выдаётся преподавателем, ~1 000 000 строк
  sql/02_plans_before.sql
  sql/03_indexes.sql
  plans/                 # сохранённые планы (txt)
  cmd/insertbench/main.go
  REPORT.md              # таблица + вывод
```

## Подготовка
`psql -d seattle_library -f sql/01_big_table.sql` → ~1M строк, 100–150 МБ (`big_checkouts`).

## Задания
1. Планы **без индексов** (сохранить в `plans/`):
   - (а) `SUM(checkouts) WHERE checkoutyear=2019 AND materialtype='<тип варианта V>'`
   - (б) `WHERE title = '<название>'`
   - (в) `WHERE title LIKE '<начало>%'`
   - (г) `WHERE title ILIKE '%<слово>%'`
2. Составной B-tree `(checkoutyear, materialtype)`; повторить (а); запрос только по `materialtype` — ускорился? Объяснить порядок столбцов (leftmost prefix).
3. B-tree по `title`; повторить (б), (в). Для (в) — `text_pattern_ops`, если collation не «C».
4. Удалить B-tree, создать hash по `title`. Сравнить размеры (`pg_relation_size`); показать, что hash не помогает для `LIKE`.
5. GIN по `to_tsvector('english', title)`. Сравнить `ILIKE '%слово%'` vs `to_tsvector(...) @@ to_tsquery('слово')`: время и число строк (объяснить расхождение — стемминг).
6. Цена индексов: вставить 100 000 строк в таблицу без индексов и с тремя индексами (Go-бенчмарк), записать оба времени.

## Что показать (REPORT.md)
Таблица «запрос — без индекса — с индексом — тип узла (Seq Scan / Index Scan / Bitmap Heap Scan)» + вывод 3–4 предложения: какой индекс когда нужен.

## Критерии (100)
| Критерий | Баллы |
|---|---|
| Планы «до» для 4 запросов | 15 |
| Составной индекс + порядок столбцов | 20 |
| B-tree/hash для title, размеры | 20 |
| GIN и сравнение с ILIKE | 20 |
| Цена индексов при вставке | 10 |
| Таблица и вывод | 15 |

> Сравнивать «до/после» только на своей машине.
