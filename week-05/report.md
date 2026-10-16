# Неделя 5. Практическое занятие №5

**Тема:** модель ролевого управления доступом RBAC
**Выполнил:** Meorwik
**СУБД:** PostgreSQL 16, база `university`

## 1. Цель работы

Спроектировать и реализовать ролевую модель доступа (RBAC) для информационной системы университета. Права выдаются ролям, роли назначаются пользователям. Кроме того, нужно построить иерархию ролей, проанализировать разделение обязанностей и проверить, что модель действительно работает.

Файлы: [`setup.sql`](setup.sql) (таблицы, роли, права, пользователи, иерархия), [`checks.sql`](checks.sql) (проверки, разделение обязанностей, итоговая матрица), [`checks_output.txt`](checks_output.txt) (полный вывод СУБД).

## 2. Исходная модель RBAC

```
Пользователь  →  Роль  →  Права  →  Ресурс БД

teacher01  →  teacher_role  →  SELECT           →  students, teachers, groups
                            →  SELECT/INSERT/UPDATE  →  grades
```

В системе 500 студентов, 50 преподавателей, 10 бухгалтеров, 5 сотрудников деканата, 3 аналитика и 2 администратора, то есть 570 человек. При индивидуальной выдаче пришлось бы настраивать права 570 раз. В RBAC права описываются один раз для каждой из 6 ролей, а каждому новому сотруднику выполняется одна команда `GRANT <роль> TO <пользователь>`.

## 3. Проектирование ролей (задание 1)

| Роль          | Назначение                         | Необходимые ресурсы                                |
|---------------|------------------------------------|----------------------------------------------------|
| Student       | Работа со своими учебными данными  | students, grades                                   |
| Teacher       | Работа с учебным процессом         | students, teachers, groups, grades                 |
| Accountant    | Работа с оплатами                  | payments                                           |
| Dean          | Работа с учебной информацией       | students, teachers, groups, grades, reports        |
| Analyst       | Анализ данных                      | students, grades, payments, reports                |
| Administrator | Администрирование БД               | все объекты                                        |

## 4. Созданные роли и пользователи (задания 2, 4)

```sql
CREATE ROLE student_role;
CREATE ROLE teacher_role;
CREATE ROLE accountant_role;
CREATE ROLE dean_role;
CREATE ROLE analyst_role;
CREATE ROLE admin_role;

CREATE USER student01    WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher01    WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER accountant01 WITH PASSWORD 'Accountant_Strong_123!';
CREATE USER dean01       WITH PASSWORD 'Dean_Strong_123!';
CREATE USER analyst01    WITH PASSWORD 'Analyst_Strong_123!';
CREATE USER admin01      WITH PASSWORD 'Admin_Strong_123!' CREATEROLE;

GRANT student_role    TO student01;
GRANT teacher_role    TO teacher01;
GRANT accountant_role TO accountant01;
GRANT dean_role       TO dean01;
GRANT analyst_role    TO analyst01;
GRANT admin_role      TO admin01;
```

Роли созданы как `NOLOGIN` (`rolcanlogin = f`), то есть войти под ролью нельзя. Входят только пользователи, а права они получают через членство в роли.

## 5. Права ролей (задание 3)

```sql
-- студент
GRANT SELECT ON students, grades TO student_role;

-- преподаватель (без DELETE)
GRANT SELECT ON students, teachers, groups TO teacher_role;
GRANT SELECT, INSERT, UPDATE ON grades TO teacher_role;
GRANT USAGE ON SEQUENCE grades_id_seq TO teacher_role;

-- бухгалтер
GRANT SELECT, INSERT, UPDATE ON payments TO accountant_role;
GRANT USAGE ON SEQUENCE payments_id_seq TO accountant_role;

-- деканат
GRANT SELECT ON students, teachers, groups TO dean_role;
GRANT SELECT, INSERT, UPDATE ON grades, reports TO dean_role;
GRANT USAGE ON SEQUENCE grades_id_seq, reports_id_seq TO dean_role;

-- аналитик
GRANT SELECT ON students, grades, payments, reports TO analyst_role;

-- администратор
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
```

`USAGE` на последовательности я добавил сам. Без него `INSERT` в таблицу с полем `SERIAL` не проходит: роль не может получить следующее значение `id`.

## 6. Матрица доступа

Таблица построена запросом к `has_table_privilege` после выполнения всех заданий и совпадает с матрицей из методички:

| Роль          | students | teachers | groups | grades | payments | reports | users  |
|---------------|----------|----------|--------|--------|----------|---------|--------|
| Student       | R        | —        | —      | R      | —        | —       | —      |
| Teacher       | R        | R        | R      | R/I/U  | —        | —       | —      |
| Accountant    | —        | —        | —      | —      | R/I/U    | —       | —      |
| Dean          | R        | R        | R      | R/I/U  | —        | R/I/U   | —      |
| Analyst       | R        | —        | —      | R      | R        | R       | —      |
| Administrator | Полный   | Полный   | Полный | Полный | Полный   | Полный  | Полный |

R — SELECT, I — INSERT, U — UPDATE, D — DELETE.

## 7. Результаты проверки (задание 7)

### Разрешённые операции

| Пользователь | Операция                                                 | Ответ СУБД    |
|--------------|----------------------------------------------------------|---------------|
| student01    | `SELECT * FROM students`                                 | 3 строки      |
| teacher01    | `UPDATE grades SET grade = 90 WHERE id = 1`              | `UPDATE 1`    |
| teacher01    | `INSERT INTO grades (...) VALUES (1, 1, 'Операционные системы', 88)` | `INSERT 0 1` |
| accountant01 | `INSERT INTO payments (...)`                             | `INSERT 0 1`  |
| dean01       | `INSERT INTO reports (report_name) VALUES ('Отчёт деканата')` | `INSERT 0 1` |
| analyst01    | `SELECT * FROM payments`                                 | 4 строки      |
| admin01      | `CREATE USER new_teacher ...` / `DROP USER new_teacher`  | `CREATE ROLE` / `DROP ROLE` |

### Запрещённые операции

| Пользователь | Операция                                                   | Ответ СУБД                              |
|--------------|------------------------------------------------------------|-----------------------------------------|
| student01    | `UPDATE students SET full_name = 'Test Student' WHERE id = 1` | `permission denied for table students` |
| student01    | `SELECT * FROM payments`                                   | `permission denied for table payments`  |
| teacher01    | `DELETE FROM grades WHERE id = 1`                          | `permission denied for table grades`    |
| accountant01 | `UPDATE grades SET grade = 100 WHERE id = 1`               | `permission denied for table grades`    |
| dean01       | `SELECT * FROM payments`                                   | `permission denied for table payments`  |
| analyst01    | `UPDATE payments SET amount = 0 WHERE id = 1`              | `permission denied for table payments`  |
| analyst01    | `DELETE FROM reports WHERE id = 1`                         | `permission denied for table reports`   |

## 8. Иерархия ролей (задание 5)

```sql
CREATE ROLE employee_role;
GRANT SELECT ON students TO employee_role;

CREATE ROLE senior_employee_role;
GRANT employee_role TO senior_employee_role;
GRANT SELECT ON teachers, groups TO senior_employee_role;
```

```
senior_employee_role ── SELECT teachers, SELECT groups
        │
        ▼ (наследует)
  employee_role ──────── SELECT students
```

Для проверки я создал пользователей `employee01` (роль `employee_role`) и `senior01` (роль `senior_employee_role`):

| Пользователь | students              | teachers                          | groups    |
|--------------|-----------------------|-----------------------------------|-----------|
| employee01   | ✓                     | ✗ `permission denied`             | —         |
| senior01     | ✓ (унаследовано)      | ✓                                 | ✓         |

`senior01` читает `students`, хотя прямого права на эту таблицу у `senior_employee_role` нет. Право пришло по цепочке ролей.

## 9. Разделение обязанностей (задание 6)

| Роль 1     | Роль 2        | Можно ли совмещать? | Почему |
|------------|---------------|---------------------|--------|
| Accountant | Administrator | **Нет**             | Один человек сможет изменить платёж, выдать себе любые права, удалить данные и стереть следы. Контроль над деньгами и над системой контроля окажутся в одних руках. |
| Teacher    | Student       | **Нет**             | Студент с ролью преподавателя может изменить собственные оценки. Это конфликт интересов. |
| Analyst    | Accountant    | **Нежелательно**    | Аналитик готовит отчёты по платежам. Если он же меняет платежи, то может подогнать данные под отчёт, и независимой проверки не будет. |
| Dean       | Teacher       | **Можно, с контролем** | Обе роли работают с учебным процессом, и в вузах это часто один человек (например, заведующий кафедрой). Изменения оценок в таком случае стоит журналировать. |

Совмещение я проверил на практике. Выдал `admin01` дополнительно `accountant_role`, и запрос поиска конфликтов сразу нашёл нарушение:

```
 username |      role1      |   role2
----------+-----------------+------------
 admin01  | accountant_role | admin_role
```

После `REVOKE accountant_role FROM admin01` пользователей с этой парой ролей не осталось (`count = 0`).

## 10. Вывод

**Как RBAC упрощает управление безопасностью базы данных?**

1. **Меньше ручной работы.** Права описываются для 6 ролей, а не для 570 пользователей. Новому сотруднику достаточно одной команды `GRANT роль TO пользователь`.
2. **Меньше ошибок.** Все пользователи одной категории получают одинаковый набор прав. Ситуация, когда одному преподавателю случайно выдали `DELETE`, а другому нет, исключена.
3. **Изменения в одном месте.** Если преподавателям понадобится новая таблица, право выдаётся `teacher_role` и сразу действует для всех 50 преподавателей.
4. **Прозрачность и аудит.** Матрицу «роль → права» легко получить из системного каталога и сравнить с политикой безопасности. Конфликты ролей тоже ищутся одним запросом.
5. **Иерархия** позволяет не дублировать общие права: старшая роль наследует права базовой.
6. **Принцип минимальных привилегий и разделение обязанностей** закладываются в саму модель ролей, а не зависят от аккуратности администратора при выдаче каждого права.
