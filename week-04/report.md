# Неделя 4. Практическое занятие №4

**Тема:** авторизация и разграничение прав доступа в СУБД
**Выполнил:** Meorwik
**СУБД:** PostgreSQL 16, база `university`

## 1. Цель работы

Защитить базу данных университета с помощью разграничения прав. Для этого нужно составить матрицу доступа, реализовать её командами `GRANT` и `REVOKE`, затем перейти от индивидуальных прав к ролям и проверить принцип минимальных привилегий.

Файлы: [`setup.sql`](setup.sql) (таблицы, данные, пользователи, задания 1–3), [`checks.sql`](checks.sql) (задания 3–7 и проверки), [`checks_output.txt`](checks_output.txt) (полный вывод СУБД).

## 2. Пользователи (задание 1)

| Пользователь      | Назначение    | Пароль            |
|-------------------|---------------|-------------------|
| `student_user`    | студент       | `Student_123!`    |
| `teacher_user`    | преподаватель | `Teacher_123!`    |
| `accountant_user` | бухгалтер     | `Accountant_123!` |
| `db_admin`        | администратор | `Admin_123!`      |
| `analyst_user`    | аналитик (задание 7) | `Analyst_123!` |

В методичке таблица `payments` не заполнена, поэтому я добавил в неё три платежа. Без них бухгалтеру и аналитику нечего было бы читать.

## 3. Матрица доступа (задание 2)

Сначала составил матрицу сам, исходя из обязанностей каждой роли:

| Роль       | students | teachers | grades  | payments |
|------------|----------|----------|---------|----------|
| Student    | R        | —        | R       | —        |
| Teacher    | R        | R        | R/U     | —        |
| Accountant | —        | —        | —       | R/U      |
| Analyst    | R        | —        | R       | R        |
| Admin      | R/C/U/D  | R/C/U/D  | R/C/U/D | R/C/U/D  |

Рассуждения:
- студенту хватает чтения списка студентов и оценок, менять оценки он не должен;
- преподавателю нужны студенты, коллеги и оценки, а изменять он может только оценки. Удалять оценки ему не нужно: исправление делается через `UPDATE`;
- бухгалтер работает только с платежами, учебные данные ему не нужны;
- администратор обслуживает базу, поэтому ему нужен полный доступ.

Моя матрица совпала с рекомендованной.

Администратору я выдал не `SUPERUSER`, а явные права на все четыре таблицы и атрибут `CREATEROLE`. Этого хватает для обслуживания базы и управления пользователями, а обходить любые проверки он не может.

## 4. GRANT (задание 3)

```sql
GRANT SELECT ON students, grades TO student_user;

GRANT SELECT ON students, teachers, grades TO teacher_user;
GRANT UPDATE ON grades TO teacher_user;

GRANT SELECT, UPDATE ON payments TO accountant_user;
```

| Пользователь      | Операция                                  | Результат | Ответ СУБД                                    |
|-------------------|-------------------------------------------|-----------|-----------------------------------------------|
| student_user      | `SELECT * FROM students` / `grades`       | Разрешено | 3 строки                                      |
| student_user      | `UPDATE grades SET grade = 100`           | Запрещено | `permission denied for table grades`          |
| student_user      | `SELECT * FROM payments`                  | Запрещено | `permission denied for table payments`        |
| teacher_user      | `SELECT * FROM grades`                    | Разрешено | 3 строки                                      |
| teacher_user      | `UPDATE grades SET grade = 95 WHERE id=1` | Разрешено | `UPDATE 1`                                    |
| teacher_user      | `DELETE FROM grades WHERE id = 1`         | Запрещено | `permission denied for table grades`          |
| accountant_user   | `SELECT * FROM payments`                  | Разрешено | 3 строки                                      |
| accountant_user   | `UPDATE payments SET amount = 100000`     | Разрешено | `UPDATE 1`                                    |
| accountant_user   | `SELECT * FROM students`                  | Запрещено | `permission denied for table students`        |

Студент не может изменить оценку, потому что у `student_user` нет привилегии `UPDATE` на `grades`.

## 5. REVOKE (задание 4)

```sql
GRANT DELETE ON grades TO teacher_user;      -- «ошибочно» выданное право
-- teacher_user: DELETE FROM grades WHERE id = 1;  -> DELETE 1 (выполнял в транзакции и откатил)
REVOKE DELETE ON grades FROM teacher_user;   -- исправление
-- teacher_user: DELETE FROM grades WHERE id = 1;  -> ERROR: permission denied for table grades
```

Удаление проверял внутри `BEGIN ... ROLLBACK`, чтобы не потерять тестовую оценку.

## 6. Роли (задание 5)

```sql
CREATE ROLE student_role;
CREATE ROLE teacher_role;
CREATE ROLE accountant_role;

GRANT SELECT ON students, grades TO student_role;
GRANT SELECT ON students, teachers, grades TO teacher_role;
GRANT UPDATE ON grades TO teacher_role;
GRANT SELECT, UPDATE ON payments TO accountant_role;

GRANT student_role    TO student_user;
GRANT teacher_role    TO teacher_user;
GRANT accountant_role TO accountant_user;

-- убираю прямые права из задания 3, чтобы доступ шёл только через роли
REVOKE ALL ON students, teachers, grades, payments
  FROM student_user, teacher_user, accountant_user;
```

После этого в `information_schema.role_table_grants` права остались только у ролей и у `db_admin`. Пользователи при этом продолжили работать: студент читает оценки, преподаватель обновляет оценку, бухгалтер читает платежи. Значит, права наследуются через членство в роли.

```
student_user    → student_role    → SELECT students, SELECT grades
teacher_user    → teacher_role    → SELECT students, teachers, grades; UPDATE grades
accountant_user → accountant_role → SELECT, UPDATE payments
analyst_user    → analyst_role    → SELECT students, grades, payments
```

## 7. Минимальные привилегии преподавателя (задание 6)

| Операция от teacher_user                       | Результат | Ответ СУБД                                  |
|------------------------------------------------|-----------|---------------------------------------------|
| `DELETE FROM students WHERE id = 1`            | Запрещено | `permission denied for table students`      |
| `DROP TABLE students`                          | Запрещено | `must be owner of table students`           |
| `CREATE USER test_user WITH PASSWORD '...'`    | Запрещено | `permission denied to create role`          |

Вывод: у `teacher_user` есть рабочие права, но нет административных привилегий.

## 8. Роль аналитика (задание 7)

```sql
CREATE ROLE analyst_role;
GRANT SELECT ON students, grades, payments TO analyst_role;
CREATE USER analyst_user WITH PASSWORD 'Analyst_123!';
GRANT analyst_role TO analyst_user;
```

| Операция от analyst_user                           | Результат | Ответ СУБД                             |
|----------------------------------------------------|-----------|----------------------------------------|
| `SELECT * FROM students`                           | Разрешено | 3 строки                               |
| `SELECT * FROM payments`                           | Разрешено | 3 строки                               |
| `UPDATE students SET group_name = 'IT-25' ...`     | Запрещено | `permission denied for table students` |
| `DELETE FROM grades WHERE id = 1`                  | Запрещено | `permission denied for table grades`   |
| `CREATE USER test_user ...`                        | Запрещено | `permission denied to create role`     |

## 9. Итоговая проверка

Матрица получена запросом к `has_table_privilege` (R = SELECT, C = INSERT, U = UPDATE, D = DELETE):

| Пользователь    | students | teachers | grades | payments |
|-----------------|----------|----------|--------|----------|
| student_user    | R---     | ----     | R---   | ----     |
| teacher_user    | R---     | R---     | R-U-   | ----     |
| accountant_user | ----     | ----     | ----   | R-U-     |
| analyst_user    | R---     | ----     | R---   | R---     |
| db_admin        | RCUD     | RCUD     | RCUD   | RCUD     |

Сводная таблица по операциям:

| Пользователь | SELECT | INSERT | UPDATE | DELETE |
|--------------|:------:|:------:|:------:|:------:|
| Student      | ✓      | ✗      | ✗      | ✗      |
| Teacher      | ✓      | ✗      | ✓      | ✗      |
| Accountant   | ✓*     | ✗      | ✓*     | ✗      |
| Analyst      | ✓      | ✗      | ✗      | ✗      |
| Admin        | ✓      | ✓      | ✓      | ✓      |

\* только таблица `payments`.

## 10. Вывод

Права в PostgreSQL выдаются на конкретную операцию над конкретной таблицей. Всё, что не выдано явно, запрещено, и СУБД отвечает ошибкой `permission denied`. Удалить таблицу может только её владелец, а создать пользователя только роль с `CREATEROLE`. Поэтому обычные права на данные не дают административных возможностей.

Роли оказались удобнее индивидуальной настройки. Права описываются один раз на роль, а пользователю достаточно назначить нужную роль. Если ошибочно выдать лишнее право, его можно быстро отозвать через `REVOKE`, и проверка сразу это подтверждает.
