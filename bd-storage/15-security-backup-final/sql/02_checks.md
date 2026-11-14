# Таблица проверок ролей

Запуск: `./run_checks.sh`

| Операция | app_reader | app_writer |
|---|---|---|
| SELECT | разрешено | разрешено |
| INSERT в titles | `permission denied for table titles` | разрешено |
| INSERT в checkout_facts | `permission denied for table checkout_facts` | разрешено |
| UPDATE checkout_facts | `permission denied for table checkout_facts` | разрешено |
| DELETE | `permission denied for table checkout_facts` | `permission denied for table checkout_facts` |
| DROP TABLE | `must be owner of table subjects` | `must be owner of table subjects` |
| CREATE TABLE | `permission denied for schema public` | `permission denied for schema public` |
