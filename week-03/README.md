# Неделя 3. ПЗ №3. Пользователи, аутентификация и права доступа

| Файл | Что внутри |
|------|------------|
| `assignment.pdf` | задание |
| `setup.sql` | создание таблиц, данных, пользователей, ролей и прав (выполняется автоматически при первом запуске контейнера) |
| `checks.sql` | ход работы и проверки разрешённых и запрещённых операций |
| `checks_output.txt` | вывод PostgreSQL 16 после прогона `checks.sql` |
| `report.md` | отчёт |

## Запуск

```bash
docker compose up -d                                                   # поднять БД, setup.sql выполнится сам
docker compose exec db psql -U postgres -d university -f /checks.sql   # прогнать проверки
docker compose exec db psql -U postgres -d university                  # зайти в psql вручную
docker compose down                                                    # выключить и удалить контейнер
```

Данные не сохраняются между запусками: после `down` и `up` база создаётся заново из `setup.sql`, поэтому `checks.sql` всегда выполняется на чистых данных.
