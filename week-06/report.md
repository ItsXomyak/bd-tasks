# Неделя 6. Практическое занятие №6

**Тема:** защита данных на уровне таблиц, строк и представлений
**Выполнил:** Meorwik
**СУБД:** PostgreSQL 16, база `university`

## 1. Цель работы

Научиться защищать данные на разных уровнях. Для этого нужно было выдавать и отзывать права на таблицы, ограничивать доступ к отдельным столбцам, создать защищённое представление `VIEW`, разграничить доступ к строкам с помощью Row-Level Security и проверить, что запреты действительно срабатывают.

Файлы: [`setup.sql`](setup.sql) (таблицы, данные, роли, права, VIEW, RLS), [`checks.sql`](checks.sql) (все проверки), [`checks_output.txt`](checks_output.txt) (полный вывод СУБД).

## 2. Таблицы и тестовые данные (задание 1)

```sql
CREATE TABLE students (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    group_name  VARCHAR(50)  NOT NULL,
    email       VARCHAR(100),
    scholarship NUMERIC(10,2)
);

CREATE TABLE grades (
    id               SERIAL PRIMARY KEY,
    student_id       INT  NOT NULL REFERENCES students(id),
    teacher_username TEXT NOT NULL,
    subject          VARCHAR(100) NOT NULL,
    grade            INT  NOT NULL CHECK (grade BETWEEN 0 AND 100)
);

INSERT INTO students (full_name, group_name, email, scholarship) VALUES
    ('Иван Петров',    'IT-21', 'ivan@example.com',    25000),
    ('Анна Садыкова',  'IT-22', 'anna@example.com',    30000),
    ('Данияр Ахметов', 'IT-21', 'daniyar@example.com', 20000),
    ('Мария Иванова',  'IT-23', 'maria@example.com',   28000);

INSERT INTO grades (student_id, teacher_username, subject, grade) VALUES
    (1, 'teacher01', 'Базы данных',       90),
    (2, 'teacher01', 'Базы данных',       85),
    (3, 'teacher02', 'Компьютерные сети', 92),
    (4, 'teacher02', 'Компьютерные сети', 88);
```

**Вопрос: какие данные в `students` конфиденциальны и почему?**

- `scholarship` (стипендия) — это финансовая информация о конкретном человеке. Преподавателю она не нужна для работы, а её раскрытие нарушает приватность студента.
- `email` — персональные данные, по которым можно связаться с человеком. Утечка адреса открывает путь к спаму и фишингу. Обрабатывать его должны только те, кому он нужен.
- `full_name` вместе с `group_name` тоже являются персональными данными. Но без них учебный процесс невозможен, поэтому их открывают ограниченному кругу ролей.

## 3. Роли и права на столбцы (задание 2)

```sql
CREATE ROLE teacher_limited;
CREATE ROLE accountant_limited;

GRANT SELECT (id, full_name, group_name) ON students TO teacher_limited;
GRANT SELECT (id, scholarship)           ON students TO accountant_limited;
```

| Операция                                        | Ожидаемый результат                 | Фактический результат |
|-------------------------------------------------|-------------------------------------|-----------------------|
| Преподаватель читает ФИО (`id, full_name, group_name`) | Разрешено                    | Разрешено, 4 строки   |
| Преподаватель читает стипендию                  | Запрещено при отсутствии других прав | `permission denied for table students` |
| Преподаватель читает email                      | Запрещено                           | `permission denied for table students` |
| Преподаватель делает `SELECT *`                 | Запрещено                           | `permission denied for table students` |
| Бухгалтер читает стипендию                      | Разрешено                           | Разрешено, 4 строки   |
| Бухгалтер читает ФИО                            | Запрещено                           | `permission denied for table students` |
| Преподаватель изменяет стипендию                | Запрещено при отсутствии права UPDATE | `permission denied for table students` |

`SELECT *` тоже запрещён, потому что `*` раскрывается во все столбцы, включая закрытые. Право на столбец действует только на этот столбец и не даёт других привилегий на таблицу.

## 4. Представление student_public_info (задание 3)

```sql
CREATE VIEW student_public_info AS
SELECT id, full_name, group_name
FROM students;

GRANT SELECT ON student_public_info TO teacher_limited;

-- Часть В: убираем прямой доступ к таблице
REVOKE SELECT ON students FROM teacher_limited;
```

`SELECT * FROM student_public_info` от имени `teacher_limited` возвращает три столбца (`id`, `full_name`, `group_name`) и 4 строки. Стипендии и email в нём нет.

**Наблюдение.** После `REVOKE SELECT ON students FROM teacher_limited` в `information_schema.column_privileges` у роли не осталось ни одного столбца. Отзыв права на уровне таблицы в PostgreSQL отзывает и права на отдельные столбцы. Поэтому после части В прямой `SELECT id, full_name, group_name FROM students` тоже запрещён, и преподаватель работает только через представление. Само представление продолжает работать, потому что выполняется с правами своего владельца (`postgres`).

**Вопросы:**

1. *Какие данные скрывает представление?* Столбцы `email` и `scholarship`, то есть контактные и финансовые данные студента.
2. *Почему VIEW не заменяет настройку прав на исходную таблицу?* Представление — это ещё один путь к данным, а не замок на таблице. Если у пользователя осталось право `SELECT` на `students` (выданное напрямую, через другую роль или через `PUBLIC`), он прочитает таблицу целиком в обход представления. Поэтому прямые права на таблицу нужно отдельно отозвать и проверить.
3. *Когда представление удобнее прав на всю таблицу?* Когда нужно показать подмножество столбцов или строк (например, только студентов своей группы), объединить данные нескольких таблиц, переименовать или вычислить поля, а также дать одинаковый «срез» многим ролям. Структуру таблицы при этом можно менять, не трогая права пользователей.

## 5. Row-Level Security (задание 4)

```sql
CREATE ROLE teacher01 LOGIN PASSWORD 'Teacher01_Strong!';
CREATE ROLE teacher02 LOGIN PASSWORD 'Teacher02_Strong!';

CREATE ROLE teacher_rls_role;
GRANT teacher_rls_role TO teacher01;
GRANT teacher_rls_role TO teacher02;

GRANT SELECT, UPDATE ON grades TO teacher_rls_role;

ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

CREATE POLICY grades_select_policy
    ON grades
    FOR SELECT
    TO teacher_rls_role
    USING (teacher_username = current_user);

CREATE POLICY grades_update_policy
    ON grades
    FOR UPDATE
    TO teacher_rls_role
    USING (teacher_username = current_user)
    WITH CHECK (teacher_username = current_user);
```

- `USING` определяет, какие существующие строки пользователь видит и может изменять.
- `WITH CHECK` проверяет новую версию строки после изменения.

Политики в системном каталоге (`pg_policies`):

```
      policyname      |  cmd   |       roles        |               qual                |            with_check
----------------------+--------+--------------------+-----------------------------------+-----------------------------------
 grades_select_policy | SELECT | {teacher_rls_role} | (teacher_username = CURRENT_USER) |
 grades_update_policy | UPDATE | {teacher_rls_role} | (teacher_username = CURRENT_USER) | (teacher_username = CURRENT_USER)
```

## 6. Проверка защиты данных (задание 5)

Проверки RLS выполнялись при прямом подключении под `teacher01` и `teacher02` (`\c - teacher01`). Так `current_user` совпадает с именем преподавателя. Проверки ролей `teacher_limited` и `accountant_limited` выполнялись через `SET ROLE`, потому что это роли без права входа.

**teacher01:**

```
SELECT * FROM grades ORDER BY id;
 id | student_id | teacher_username |   subject   | grade
----+------------+------------------+-------------+-------
  1 |          1 | teacher01        | Базы данных |    90
  2 |          2 | teacher01        | Базы данных |    85

UPDATE grades SET grade = 95 WHERE id = 1;    -> UPDATE 1
UPDATE grades SET grade = 100 WHERE id = 3;   -> UPDATE 0
UPDATE grades SET teacher_username = 'teacher02' WHERE id = 1;
  -> ERROR: new row violates row-level security policy for table "grades"
DELETE FROM grades WHERE id = 1;              -> ERROR: permission denied for table grades
```

**teacher02:**

```
SELECT * FROM grades ORDER BY id;
 id | student_id | teacher_username |      subject      | grade
----+------------+------------------+-------------------+-------
  3 |          3 | teacher02        | Компьютерные сети |    92
  4 |          4 | teacher02        | Компьютерные сети |    88
```

Оценка в строке № 3 осталась 92: попытка teacher01 её изменить ничего не изменила.

### Таблица результатов

| Проверка                         | Ожидаемый результат | Фактический результат |
|----------------------------------|---------------------|-----------------------|
| Чтение разрешённых столбцов      | Разрешено           | Разрешено: `id, full_name, group_name`, 4 строки (до отзыва прав в задании 3В) |
| Чтение стипендии преподавателем  | Запрещено           | Запрещено: `permission denied for table students` |
| Чтение через VIEW                | Разрешено           | Разрешено: 3 столбца, 4 строки |
| Чтение оценок teacher01          | Только свои строки  | Только свои: строки 1 и 2 |
| Чтение оценок teacher02          | Только свои строки  | Только свои: строки 3 и 4 |
| Изменение чужой оценки           | Не изменяется       | Не изменяется: `UPDATE 0`, оценка в строке 3 осталась 92 |
| Передача своей оценки другому преподавателю | Запрещено | Запрещено: `new row violates row-level security policy` |
| Удаление оценки преподавателем   | Запрещено           | Запрещено: `permission denied for table grades` |

## 7. Доработка: ограничение обновляемых столбцов

В методичке отмечено, что преподаватель не должен менять `teacher_username`. `WITH CHECK` уже не даёт переписать строку на другого преподавателя. Но по принципу минимальных привилегий преподавателю достаточно менять только оценку, поэтому я сузил право `UPDATE` до одного столбца:

```sql
REVOKE UPDATE ON grades FROM teacher_rls_role;
GRANT UPDATE (grade) ON grades TO teacher_rls_role;
```

| Операция от teacher01                                       | Результат                              |
|-------------------------------------------------------------|----------------------------------------|
| `UPDATE grades SET teacher_username = 'teacher01' WHERE id = 3` | `permission denied for table grades`   |
| `UPDATE grades SET subject = 'Другой предмет' WHERE id = 1`  | `permission denied for table grades`   |
| `UPDATE grades SET grade = 96 WHERE id = 1`                  | `UPDATE 1`                             |

Теперь защита двухуровневая: права на столбцы определяют, *что* можно менять, а RLS определяет, *в каких строках*.

## 8. Вывод

В работе использованы четыре механизма защиты:

| Механизм                     | Что ограничивает                    | Какую угрозу уменьшает |
|------------------------------|-------------------------------------|------------------------|
| Права на таблицы (`GRANT`/`REVOKE`) | Операции над таблицей целиком | Несанкционированное чтение, изменение и удаление данных |
| Права на столбцы             | Доступ к отдельным полям            | Утечку конфиденциальных полей (стипендия, email) пользователям, которым нужна только часть записи |
| Представление `VIEW`         | Набор данных, который видит роль    | Случайное или намеренное получение лишних данных; даёт единый безопасный «срез» таблицы |
| Row-Level Security           | Доступ к отдельным строкам          | Просмотр и изменение чужих записей (оценки другого преподавателя), подмену владельца строки |

Для защиты базы недостаточно просто создать пользователей и назначить им роли. Нужно определить, какие таблицы, столбцы и строки доступны каждой категории пользователей, и затем проверить, что запреты действительно работают. Проверка показала один неочевидный момент: отзыв права на таблицу снимает и права на её столбцы. Поэтому после любого `REVOKE` реальные права нужно перепроверять.
