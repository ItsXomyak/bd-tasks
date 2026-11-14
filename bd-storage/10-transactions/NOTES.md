# Занятие 10. Наблюдения

Запуск всего: `./run.sh` (таблицы `copies`, `loans` из `sql/00_setup_w10.sql`, вывод в `output/`).
Сессии — отдельные соединения pgx из Go.

## 1. Атомарность (`cmd/atomicity`)
В транзакции `UPDATE copies SET available = available - 1`, затем `INSERT INTO loans (reader) VALUES (NULL)` → ошибка `23502 null value in column "reader" violates not-null constraint`.
- Внутри транзакции А: `available=99`; вторая сессия до COMMIT видит `100`.
- После `ROLLBACK`: `available=100`, `loans=0` — отменились **обе** операции, транзакция атомарна.

## 2. READ COMMITTED и REPEATABLE READ (`cmd/isolation`)
| Уровень | Первое чтение | Второе чтение (после COMMIT другой сессии) |
|---|---|---|
| READ COMMITTED | 10 | **7** (неповторяемое чтение) |
| REPEATABLE READ | 10 | **10** (снимок на начало транзакции) |

## 3. Потерянное обновление (`cmd/lostupdate`, 50 горутин, старт 100)
| Способ | Ожидалось | Получено |
|---|---|---|
| `SELECT` → `-1` в коде → `UPDATE SET available = v` | 50 | **95** (потеряно 45) |
| `UPDATE ... SET available = available - 1` | 50 | 50 |
| `SELECT ... FOR UPDATE` + `UPDATE` | 50 | 50 |

Причина: горутины читают одно и то же старое значение и перезаписывают друг друга. Атомарный `UPDATE` и блокировка строки `FOR UPDATE` сериализуют доступ.

## 4. Serialization failure (`cmd/serializable`)
10 горутин на REPEATABLE READ: чтение → `UPDATE`. Конфликты дают SQLSTATE `40001` (`could not serialize access due to concurrent update`). Транзакция повторяется (до 50 попыток с паузой): итог 90 как и ожидалось, повторов 25, ошибок без восстановления 0.

## 5. Deadlock (`cmd/deadlock`)
A: строка 5 → 6, B: строка 6 → 5. Одна из транзакций получает `40P01 deadlock detected` (B), вторая коммитится. В журнале сервера (`output/05_deadlock_server_log.txt`): `Process 1700 waits for ShareLock on transaction 1016; blocked by process 1701. Process 1701 waits for ShareLock on transaction 1017; blocked by process 1700`.
Исправление: обе транзакции берут строки в одном порядке (5, затем 6) — взаимного ожидания нет, обе коммитятся (показано во втором сценарии).

## 6. MVCC (`cmd/mvcc`)
| Момент | xmin | xmax | ctid |
|---|---|---|---|
| до UPDATE | 1020 | 0 | (0,194) |
| после UPDATE | 1021 | 0 | (0,195) |

`UPDATE` в PostgreSQL не меняет строку на месте, а создаёт **новую версию** строки в новой позиции (`ctid` изменился). `xmin` — номер транзакции, создавшей версию, поэтому он вырос до номера транзакции UPDATE. Старая версия остаётся для транзакций, которым она ещё нужна.
Другая сессия во время незавершённой транзакции видит старую версию с `xmax=1022` (транзакция, которая собирается её заменить), но ещё считает её актуальной. После `ROLLBACK` `xmax=1022` в строке остаётся, но игнорируется, так как та транзакция откатилась.

## 7. READ UNCOMMITTED
Сессия B пишет `available=999` без COMMIT, сессия А на `READ UNCOMMITTED` читает `10`, а не 999 → грязного чтения нет, уровень работает как READ COMMITTED (то же на самом READ COMMITTED).
