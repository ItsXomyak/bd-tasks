# Занятие 10. Транзакции, изоляция, блокировки

**Цель:** воспроизвести COMMIT/ROLLBACK, уровни изоляции, lost update, блокировки, deadlock.
**Go:** вместо двух потоков Python — goroutines + `pgx` (отдельное соединение на каждую горутину). Ручные сценарии — две сессии psql.

## Структура
```
10-transactions/
  sql/00_setup_w10.sql        # copies(available...), loans(reader NOT NULL...)
  cmd/lostupdate/main.go      # 3 режима: naive | atomic | forupdate
  cmd/serializable/main.go    # retry на SQLSTATE 40001
  NOTES.md                    # наблюдения по каждому пункту
```

## Подготовка
`psql -d seattle_library -f sql/00_setup_w10.sql`

## Задания
1. **Атомарность** (psql): `BEGIN; UPDATE copies SET available=available-1...; INSERT INTO loans(reader=NULL...)` → ошибка NOT NULL → `ROLLBACK`; оба изменения отменены. Вторая сессия до COMMIT изменений не видит.
2. **READ COMMITTED vs REPEATABLE READ:** С1 читает `available` дважды, С2 между чтениями делает UPDATE+COMMIT. Записать, что видит С1 на каждом уровне.
3. **Lost update (Go):** N горутин: `SELECT` → `-1` в коде → `UPDATE`. Показать неверный итог. Починить:
   - `UPDATE ... SET available = available - 1`
   - `SELECT ... FOR UPDATE` в транзакции
4. **Serialization failure:** REPEATABLE READ, конфликт → `could not serialize access` (SQLSTATE `40001`, `errors.As(*pgconn.PgError)`) → повтор транзакции (цикл ≤ 5 попыток).
5. **Deadlock:** две сессии обновляют 2 строки в разном порядке; найти `deadlock detected` (SQLSTATE `40P01`) в логе; объяснить фикс — единый порядок обращения.
6. **MVCC:** `SELECT xmin, xmax, * FROM copies WHERE title_id=…` до/после UPDATE; объяснить смену `xmin` (новая версия строки).
7. **READ UNCOMMITTED** в PG = READ COMMITTED: проверить, что грязного чтения нет.

## Критерии (100)
| Критерий | Баллы |
|---|---|
| Атомарность: ROLLBACK откатывает обе операции | 15 |
| RC / RR сравнение с записанными результатами | 20 |
| Lost update + 2 исправления | 25 |
| Serialization failure с повтором | 10 |
| Deadlock воспроизведён и объяснён | 20 |
| MVCC xmin/xmax объяснён | 10 |
