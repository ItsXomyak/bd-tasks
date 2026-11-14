# Занятие 12. Отчёт

Часть А: `./run_partitioning.sh`, вывод в `output/01…05`. Часть Б: `replication/demo.sh`, вывод в `output/06_replication.txt`.

## Часть А. Партиционирование

`checkouts_part` — `PARTITION BY RANGE (checkoutyear)` на 1 000 000 строк из `big_checkouts` (занятие 9).

| Партиция | Строк |
|---|---|
| `checkouts_2010_2014` | 356 671 |
| `checkouts_2015_2019` | 356 709 |
| `checkouts_2020_2024` | 286 620 |
| **Итого** | **1 000 000** (= `big_checkouts`) |

В данных годы 2010–2023, поэтому диапазоны взяты по ним; партиция `2005_2009` из текста задания была бы пустой, и `DETACH` на ней ничего бы не показал.

### Сравнение планов
| Запрос | Время | План |
|---|---|---|
| `year = 2019`, `big_checkouts` (индекс `idx_year_material` есть) | 186 мс | Bitmap Index Scan → Bitmap Heap Scan |
| `year = 2019`, `big_checkouts` без индекса | 43 мс | Parallel Seq Scan по всей таблице |
| `year = 2019`, `checkouts_part` | **21 мс** | Seq Scan **только** `checkouts_2015_2019` (partition pruning) |
| `materialtype`, `big_checkouts` | 47 мс | Parallel Seq Scan |
| `materialtype`, `checkouts_part` | 47 мс | Parallel Append по **всем 3** партициям |

- С условием по ключу планировщик отбрасывает чужие партиции (pruning): читается треть таблицы, запрос быстрее в 2 раза относительно полного скана и в 9 раз относительно индексного плана (индекс по `checkoutyear` с 71 тыс. совпадений хуже последовательного чтения).
- Без условия по ключу (`materialtype`) ускорение исчезло: ключа партиционирования в условии нет, планировщик не знает, в какой партиции лежат строки, и читает все три — суммарно столько же страниц, сколько в одной большой таблице (47 мс против 47 мс).

### DETACH / ATTACH
| Момент | Строк в `checkouts_part` |
|---|---|
| до | 1 000 000 |
| после `DETACH PARTITION checkouts_2010_2014` | 643 329 (отсоединённая таблица: 356 671) |
| после `ATTACH PARTITION … FOR VALUES FROM (2010) TO (2015)` | 1 000 000 |

Так архивируют старые данные: отсоединённая партиция становится обычной таблицей, её можно выгрузить или удалить, не затрагивая основную.

### Год вне диапазонов
`INSERT … checkoutyear = 2200` → `ERROR: no partition of relation "checkouts_part" found for row. DETAIL: Partition key of the failing row contains (checkoutyear) = (2200).`
Решение: `CREATE TABLE checkouts_default PARTITION OF checkouts_part DEFAULT` — такие строки попадают в неё (проверено: строка с годом 2200 легла в `checkouts_default`). Минус: новые диапазоны потом нельзя добавить, пока в `DEFAULT` есть подходящие строки — их надо переносить.

### Хеш-партиционирование по `id` (3 части)
| Партиция | Строк | Доля |
|---|---|---|
| `checkouts_hash_0` | 333 263 | 33.33% |
| `checkouts_hash_1` | 333 497 | 33.35% |
| `checkouts_hash_2` | 333 240 | 33.32% |

Распределение почти идеально ровное. Поиск по `id` идёт в одну партицию (`Index Scan on checkouts_hash_2`), запрос без `id` — во все три.
Связь с шардингом: шардинг — то же хеш-разбиение, только партиции лежат на разных серверах, и по ключу (`id`) клиент или роутер сразу знает, на какой сервер идти. Запросы без ключа приходится рассылать на все шарды.

## Часть Б. Репликация и отказ

Стенд: два контейнера PostgreSQL 16 (`replication/docker-compose.yml`), на primary `wal_level=logical`, публикация `pub_books`, на replica подписка `sub_books`.

| Что проверили | Наблюдение |
|---|---|
| Начальная синхронизация | 100 строк на primary → 100 на replica |
| `INSERT/UPDATE/DELETE` на primary | доходят до replica (число строк и значение `id=1` совпали) |
| **DDL** (`ALTER TABLE … ADD COLUMN author`) | **не реплицируется**: у replica столбцы `id,title`; вставка с новым столбцом даёт `ERROR: logical replication target relation "public.books" is missing replicated column: "author"`, репликация встаёт и повторяет попытки. После ручного `ALTER TABLE` на replica строка догнала |
| Запись на replica | **возможна** (логическая реплика не read-only): строка `id=500` создана на replica и на primary не появилась |
| Остановка primary | replica продолжает отдавать чтение (102 строки) и принимает запись; в логе `could not connect to the publisher`, подписка повторяет попытки |
| Primary вернулся | replica догнала (`id=103` получена) |
| Конфликт | один и тот же `id=600` записан на обеих сторонах → на replica `ERROR: duplicate key value violates unique constraint "books_pkey"`, репликация останавливается до ручного исправления |

Вывод: логическая реплика удобна для чтения и переключения при отказе, но схему надо менять на обеих сторонах вручную, а запись в реплику ведёт к расхождению и конфликтам, поэтому реплику обычно держат только для чтения.
