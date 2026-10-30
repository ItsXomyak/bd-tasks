# Занятие 14. Интеграция: API-ключ, JSON/XML, веб-клиент

**Цель:** доработать API (занятие 8): ключ доступа, два формата, поиск, веб-клиент.
**Go:** база — `08-web-api`; `gin`, `crypto/subtle`, `encoding/xml`, `net/http` (только для Go-клиента).

## Структура
```
14-api-integration/
  (копия/продолжение 08-web-api)
  internal/api/middleware.go   # gin.HandlerFunc: проверка X-API-Key
  internal/api/xml.go          # XML-ответ
  web/client.html              # выдан преподавателем
  cmd/client/main.go           # Go-клиент (вместо requests)
  postman/collection.json      # 6 сценариев
```

## Задания
1. **Ключ:** gin-middleware (`r.Use(...)` / `group.Use(...)`), `c.GetHeader("X-API-Key")`; при отказе `c.AbortWithStatusJSON(401, ...)`. Заголовок `X-API-Key`, ключ из env `API_KEY`. Нет/неверный → 401. Сравнение: `subtle.ConstantTimeCompare` (аналог `secrets.compare_digest`). Применить через группу `api := r.Group("/"); api.Use(auth)` ко всем маршрутам данных; `GET /` (HTML) вне группы.
2. **Формат:** `/titles/top?format=json|xml`. XML: `c.XML(200, obj)` (gin использует `encoding/xml`, struct-теги). Другое значение → 422.
3. **Поиск:** `GET /search?q=` (≥ 2 символов, иначе 422), полнотекстовый: `to_tsvector(...) @@ plainto_tsquery($1)` — **параметризованно**. Проверка: `q=' OR 1=1 --` → пустой список.
4. **Клиенты:** `client.html` (fetch + заголовок ключа) и `cmd/client` на Go (`http.NewRequest` + `Header.Set`).
5. **Postman, 6 сценариев:** без ключа, неверный ключ, верный, JSON, XML, POST без ключа.
6. Страница клиента (`GET /`) — без ключа, данные — с ключом. Письменно: почему ключ нельзя «зашить» в публичную страницу (виден в исходнике); в учебной работе принимаем ограничение.

## Критерии (100)
| Критерий | Баллы |
|---|---|
| Ключ на всех маршрутах, 401 | 25 |
| JSON и XML, 422 на другой формат | 20 |
| Поиск, устойчивый к инъекции | 20 |
| Веб-клиент и Go-клиент работают | 25 |
| Postman, 6 сценариев | 10 |
