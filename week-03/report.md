# Неделя 3. Практическое занятие №3

**Тема:** создание пользователей, аутентификация и разграничение прав доступа
**Выполнил:** Meorwik
**СУБД:** PostgreSQL 16, база `university`

## 1. Цель работы

Научиться создавать пользователей в СУБД, настраивать им аутентификацию по паролю и выдавать разные права доступа. Нужно было проверить, какие операции разрешены, а какие запрещены, применить принцип минимальных привилегий, а также заблокировать и удалить учётную запись.

## 2. Созданные пользователи

| Пользователь   | Назначение    | Аутентификация | Права                                  |
|----------------|---------------|----------------|----------------------------------------|
| `student_user` | Студент       | пароль         | только чтение `students`               |
| `teacher_user` | Преподаватель | пароль         | чтение и изменение `students`          |
| `db_admin`     | Администратор | пароль         | `SUPERUSER`                            |
| `analyst_user` | Аналитик      | пароль         | только чтение `students`               |

Пароли хранятся в СУБД в виде хэша SCRAM-SHA-256 (`passwd IS NOT NULL` = `t` в `pg_user`).

## 3. Основные SQL-команды

Полный скрипт находится в [`setup.sql`](setup.sql), проверки в [`checks.sql`](checks.sql), вывод СУБД в [`checks_output.txt`](checks_output.txt).

```sql
-- CREATE USER: создание учётных записей
CREATE USER student_user WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher_user WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER db_admin     WITH PASSWORD 'Admin_Strong_123!';
CREATE USER analyst_user WITH PASSWORD 'Analyst_Strong_123!';

-- GRANT: выдача прав
GRANT CONNECT ON DATABASE university TO student_user;
GRANT USAGE   ON SCHEMA public       TO student_user;
GRANT SELECT  ON students            TO student_user;

GRANT CONNECT ON DATABASE university      TO teacher_user;
GRANT USAGE   ON SCHEMA public            TO teacher_user;
GRANT SELECT, INSERT, UPDATE ON students  TO teacher_user;

GRANT CONNECT ON DATABASE university TO analyst_user;
GRANT USAGE   ON SCHEMA public       TO analyst_user;
GRANT SELECT  ON students            TO analyst_user;

-- ALTER USER: администратор
ALTER USER db_admin WITH SUPERUSER;

-- REVOKE: минимальные привилегии для преподавателя
REVOKE INSERT ON students FROM teacher_user;

-- ALTER USER: блокировка и разблокировка
ALTER USER student_user NOLOGIN;
ALTER USER student_user LOGIN;

-- DROP USER: удаление учётной записи
CREATE USER temp_user WITH PASSWORD 'Temp_Strong_123!';
DROP USER temp_user;
```

Дополнительно я выполнил `REVOKE CONNECT ON DATABASE university FROM PUBLIC`. По умолчанию в PostgreSQL подключаться к базе может любая роль, а после этой команды подключиться могут только те, кому `CONNECT` выдан явно.

## 4. Матрица прав

Таблица построена по ответу СУБД (`has_table_privilege`) после выполнения всех заданий:

| Пользователь | SELECT | INSERT | UPDATE | DELETE | Управление пользователями |
|--------------|:------:|:------:|:------:|:------:|:-------------------------:|
| Student      | ✓      | ✗      | ✗      | ✗      | ✗                         |
| Teacher      | ✓      | ✗      | ✓      | ✗      | ✗                         |
| Admin        | ✓      | ✓      | ✓      | ✓      | ✓                         |
| Analyst      | ✓      | ✗      | ✗      | ✗      | ✗                         |

## 5. Результаты проверки

### student_user

| Операция      | Результат | Ответ СУБД                                    |
|---------------|-----------|-----------------------------------------------|
| `SELECT`      | Разрешено | выведены 3 строки                             |
| `UPDATE`      | Запрещено | `ERROR: permission denied for table students` |
| `INSERT`      | Запрещено | `ERROR: permission denied for table students` |
| `DELETE`      | Запрещено | `ERROR: permission denied for table students` |
| `CREATE USER` | Запрещено | `ERROR: permission denied to create role`     |

### teacher_user

| Операция                     | Результат | Ответ СУБД                                    |
|------------------------------|-----------|-----------------------------------------------|
| `SELECT`                     | Разрешено | выведены 3 строки                             |
| `UPDATE ... SET scholarship = 55000 WHERE id = 1` | Разрешено | `UPDATE 1`, стипендия стала 55000.00 |
| `INSERT` (до REVOKE)         | Разрешено | `INSERT 0 1`                                  |
| `DELETE`                     | Запрещено | `ERROR: permission denied for table students` |
| `CREATE USER`                | Запрещено | `ERROR: permission denied to create role`     |
| `INSERT` (после REVOKE)      | Запрещено | `ERROR: permission denied for table students` |
| `UPDATE` (после REVOKE)      | Разрешено | `UPDATE 1`                                    |

### db_admin

| Операция                  | Результат | Ответ СУБД    |
|---------------------------|-----------|---------------|
| `DELETE`                  | Разрешено | `DELETE 1`    |
| `CREATE USER temp_user`   | Разрешено | `CREATE ROLE` |
| `DROP USER temp_user`     | Разрешено | `DROP ROLE`   |

### Аутентификация и блокировка

| Ситуация                                       | Ответ СУБД                                                       |
|------------------------------------------------|------------------------------------------------------------------|
| Вход `student_user` с неверным паролем         | `FATAL: password authentication failed for user "student_user"`  |
| Вход `student_user` с верным паролем           | успешно, `current_user = student_user`                           |
| Вход после `ALTER USER student_user NOLOGIN`   | `FATAL: role "student_user" is not permitted to log in`          |
| Вход после `ALTER USER student_user LOGIN`     | успешно                                                          |

### Итоговое задание: analyst_user

| Операция                                                | Результат | Ответ СУБД                                    |
|---------------------------------------------------------|-----------|-----------------------------------------------|
| `SELECT * FROM students`                                | Разрешено | выведены 3 строки                             |
| `UPDATE students SET scholarship = 60000 WHERE id = 1`  | Запрещено | `ERROR: permission denied for table students` |
| `DELETE FROM students WHERE id = 1`                     | Запрещено | `ERROR: permission denied for table students` |
| `CREATE USER`                                           | Запрещено | `ERROR: permission denied to create role`     |

## 6. Наблюдения

1. Если у роли нет права на таблицу, PostgreSQL отвечает одинаково на любую операцию: `permission denied for table`.
2. Для `INSERT` в таблицу с полем `SERIAL` кроме права `INSERT` нужно `USAGE` на последовательность `students_id_seq`. Без этого права вставка падает на генерации `id`.
3. `NOLOGIN` не удаляет пользователя и не отбирает у него права. Он только запрещает вход. После `LOGIN` пользователь снова работает со всеми прежними правами.
4. Создавать пользователей может только роль с атрибутом `SUPERUSER` или `CREATEROLE`. Обычные права на таблицы такой возможности не дают.

## 7. Вывод

Я создал четыре учётные записи с аутентификацией по паролю и выдал им права командами `GRANT` и `REVOKE`. У каждого пользователя есть только то, что нужно для его работы: студент и аналитик только читают, преподаватель читает и изменяет, администратор управляет базой и пользователями. Проверки показали, что СУБД действительно отклоняет все операции, на которые права не выдавались. Блокировка через `NOLOGIN` позволяет временно закрыть доступ, не удаляя учётную запись.
