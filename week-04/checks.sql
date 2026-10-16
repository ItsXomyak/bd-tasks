-- Неделя 4. Ход работы и проверки к ПЗ №4 (задания 3–7 и итоговая проверка)
-- Запуск: docker compose exec db psql -U postgres -d university -f /checks.sql
\set ON_ERROR_STOP 0
\set ECHO queries
\pset footer off

\echo '=================== Задание 3. Студент ==================='
\c - student_user
SELECT * FROM students ORDER BY id;                 -- разрешено
SELECT * FROM grades ORDER BY id;                   -- разрешено
UPDATE grades SET grade = 100 WHERE id = 1;         -- запрещено: нет UPDATE
SELECT * FROM payments;                             -- запрещено

\echo '=================== Задание 3. Преподаватель ==================='
\c - teacher_user
SELECT * FROM grades ORDER BY id;                   -- разрешено
UPDATE grades SET grade = 95 WHERE id = 1;          -- разрешено
DELETE FROM grades WHERE id = 1;                    -- запрещено
SELECT * FROM payments;                             -- запрещено

\echo '=================== Задание 3. Бухгалтер ==================='
\c - accountant_user
SELECT * FROM payments ORDER BY id;                 -- разрешено
UPDATE payments SET amount = 100000 WHERE id = 1;   -- разрешено
SELECT * FROM students;                             -- запрещено
SELECT * FROM grades;                               -- запрещено

\echo '=================== Задание 4. Ошибочный GRANT DELETE и REVOKE ==================='
\c - postgres
GRANT DELETE ON grades TO teacher_user;

\c - teacher_user
BEGIN;
DELETE FROM grades WHERE id = 1;                    -- теперь разрешено
SELECT count(*) AS grades_after_delete FROM grades;
ROLLBACK;                                           -- откатываем, чтобы не потерять данные

\c - postgres
REVOKE DELETE ON grades FROM teacher_user;

\c - teacher_user
DELETE FROM grades WHERE id = 1;                    -- снова запрещено

\echo '=================== Задание 5. Роли вместо индивидуальных прав ==================='
\c - postgres
CREATE ROLE student_role;
CREATE ROLE teacher_role;
CREATE ROLE accountant_role;

GRANT SELECT ON students, grades TO student_role;
GRANT student_role TO student_user;

GRANT SELECT ON students, teachers, grades TO teacher_role;
GRANT UPDATE ON grades TO teacher_role;
GRANT teacher_role TO teacher_user;

GRANT SELECT, UPDATE ON payments TO accountant_role;
GRANT accountant_role TO accountant_user;

-- Убираем прямые права, выданные в задании 3: теперь права приходят только через роли
REVOKE ALL ON students, teachers, grades, payments FROM student_user, teacher_user, accountant_user;

-- Кто в какой роли состоит
SELECT r.rolname AS role_name, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname LIKE '%\_role'
ORDER BY 1, 2;

-- Прямых прав у пользователей больше нет, только у ролей
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND grantee <> 'postgres'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo '--- проверка, что права через роль работают'
\c - student_user
SELECT * FROM grades ORDER BY id;                   -- разрешено через student_role
\c - teacher_user
UPDATE grades SET grade = 96 WHERE id = 1;          -- разрешено через teacher_role
\c - accountant_user
SELECT * FROM payments ORDER BY id;                 -- разрешено через accountant_role

\echo '=================== Задание 6. Минимальные привилегии преподавателя ==================='
\c - teacher_user
DELETE FROM students WHERE id = 1;                  -- запрещено
DROP TABLE students;                                -- запрещено
CREATE USER test_user WITH PASSWORD 'Test_123!';    -- запрещено

\echo '=================== Задание 7. Роль аналитика ==================='
\c - postgres
CREATE ROLE analyst_role;
GRANT SELECT ON students, grades, payments TO analyst_role;
CREATE USER analyst_user WITH PASSWORD 'Analyst_123!';
GRANT analyst_role TO analyst_user;

\c - analyst_user
SELECT * FROM students ORDER BY id;                 -- разрешено
SELECT * FROM payments ORDER BY id;                 -- разрешено
UPDATE students SET group_name = 'IT-25' WHERE id = 1;  -- запрещено
DELETE FROM grades WHERE id = 1;                    -- запрещено
CREATE USER test_user WITH PASSWORD 'Test_123!';    -- запрещено

\echo '=================== Администратор ==================='
\c - db_admin
INSERT INTO teachers (full_name, department) VALUES ('Тестовый Преподаватель', 'Тест');  -- разрешено
DELETE FROM teachers WHERE department = 'Тест';     -- разрешено
CREATE USER test_user WITH PASSWORD 'Test_123!';    -- разрешено (CREATEROLE)
DROP USER test_user;

\echo '=================== Итоговая проверка: права по таблицам ==================='
\c - postgres
SELECT u AS "user", t AS "table",
       CASE WHEN has_table_privilege(u, t, 'SELECT') THEN 'R' ELSE '-' END ||
       CASE WHEN has_table_privilege(u, t, 'INSERT') THEN 'C' ELSE '-' END ||
       CASE WHEN has_table_privilege(u, t, 'UPDATE') THEN 'U' ELSE '-' END ||
       CASE WHEN has_table_privilege(u, t, 'DELETE') THEN 'D' ELSE '-' END AS rcud,
       k
FROM unnest(ARRAY['student_user', 'teacher_user', 'accountant_user', 'analyst_user', 'db_admin']) WITH ORDINALITY AS us(u, n)
CROSS JOIN unnest(ARRAY['students', 'teachers', 'grades', 'payments']) WITH ORDINALITY AS tt(t, k)
ORDER BY n, k \crosstabview "user" "table" rcud k
