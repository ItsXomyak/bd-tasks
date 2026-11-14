# Занятие 9. Отчёт по индексам

Данные: `big_checkouts`, 1 000 000 строк, 300 МБ (срез 2021 H2 размножен ×200, `checkoutyear` случайный 2010–2023).
Вариант V=2, тип `SOUNDDISC`. Collation БД `en_US.utf8`. Время — `Execution Time` из `EXPLAIN (ANALYZE, BUFFERS)`.
Воспроизведение: `./run.sh`, сырые планы в `plans/`.

## Таблица

| Запрос | Без индекса | С индексом | Узел «до» → «после» |
|---|---|---|---|
| (а) `year=2019 AND materialtype='SOUNDDISC'` | 138 мс | 39 мс (composite `(checkoutyear, materialtype)`) | Parallel Seq Scan → Bitmap Heap Scan |
| (а2) только `materialtype` | 49 мс | 53 мс (тот же composite) / 190 мс (`(materialtype, checkoutyear)`) | Seq Scan → Seq Scan / Bitmap Heap Scan |
| (б) `title = 'Find Me (unabridged)'` | 51 мс | 1.9 мс (B-tree) / 3.3 мс (hash) | Seq Scan → Bitmap Heap Scan |
| (в) `title LIKE 'The %'` (22% строк) | 62 мс | 61 мс (обычный B-tree) / 143 мс (`text_pattern_ops`) / 143 мс (hash) | Seq Scan → Seq Scan / Bitmap Heap Scan |
| (в′) `title LIKE 'Find Me%'` (0.04% строк) | 197 мс | 1.2 мс (`text_pattern_ops`) | Seq Scan → Bitmap Heap Scan |
| (г) `title ILIKE '%love%'` | 443 мс | 401 мс — индекс не используется | Seq Scan → Seq Scan |
| (г′) FTS `to_tsvector(title) @@ to_tsquery('love')` | — | 100 мс (GIN) | Bitmap Heap Scan |

## Порядок столбцов в составном индексе
B-tree отсортирован по первому столбцу, внутри равных — по второму. Запрос по `checkoutyear` + `materialtype` использует оба, поэтому индекс `(checkoutyear, materialtype)` помог (138 → 39 мс). Запрос только по `materialtype` не использует ведущий столбец, и планировщик выбрал Seq Scan (53 мс). Индекс с обратным порядком `(materialtype, checkoutyear)` для такого запроса планировщик использует, но получился медленнее Seq Scan (190 мс): `SOUNDDISC` занимает около 5% таблицы, и случайные чтения страниц при Bitmap Heap Scan дороже последовательного чтения. Правило: в начало ставят столбец, по которому фильтруют всегда.

## Размеры индексов по `title`
B-tree 7.9 МБ, hash 34 МБ. Hash работает только для `=` (3.3 мс), для `LIKE` он бесполезен — Seq Scan 143 мс. B-tree умеет и `=`, и диапазоны, и префиксный `LIKE` (с `text_pattern_ops`).

## Полнотекстовый поиск
- Размер GIN: 31 МБ.
- `ILIKE '%love%'` нашёл 20 600 строк за 401 мс, FTS — 18 600 строк за 100 мс.
- Расхождение из-за стемминга и границ слов. ILIKE находит подстроки (`Beloved`, `Lovers`, `Lovesick`, `Lover`), которых FTS не считает словом `love`. FTS находит `Loving` (основа слова `love`), которое ILIKE не находит.

## Цена индексов при вставке
100 000 строк через `COPY`: в таблицу без индексов — **161 мс**, в таблицу с тремя индексами (composite, B-tree, GIN) — **1.64 с**, то есть примерно в 10 раз дольше. Индексы занимают место (GIN 11 МБ, B-tree 4.9 МБ, composite 0.7 МБ на этих данных) и замедляют запись.

## Вывод
Индекс нужен там, где запрос селективен: `=` по названию (B-tree), префиксный `LIKE` с малой долей совпадений (B-tree с `text_pattern_ops` при не-C collation), поиск слов (GIN + `tsvector`). Если запрос возвращает большую долю таблицы, как `LIKE 'The %'` (22%) или `materialtype` (5%), Seq Scan быстрее индекса. Индекс не поможет, если запрос не использует его ведущий столбец или ищет подстроку (`ILIKE '%слово%'`), и каждый индекс ускоряет чтение за счёт замедления вставки и места на диске.
