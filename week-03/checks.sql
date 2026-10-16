-- Неделя 3. Проверки к ПЗ №3
-- Запуск: docker compose exec db psql -U postgres -d university -f /checks.sql
\set ON_ERROR_STOP 0
\set ECHO queries
\pset footer off

\echo '=================== Задание 1. Созданные пользователи ==================='
SELECT usename, usesuper, passwd IS NOT NULL AS has_password
FROM pg_user
WHERE usename IN ('student_user', 'teacher_user', 'db_admin', 'analyst_user')
ORDER BY usename;

\echo '=================== Задание 3. Проверка студента ==================='
\c - student_user
SELECT current_user;
SELECT * FROM students ORDER BY id;                            -- разрешено
UPDATE students SET scholarship = 100000 WHERE id = 1;         -- запрещено
INSERT INTO students (full_name, group_name) VALUES ('X', 'IT-00');  -- запрещено
DELETE FROM students WHERE id = 1;                             -- запрещено
CREATE USER hacker WITH PASSWORD 'Hacker_123!';                -- запрещено

\echo '=================== Проверка преподавателя ==================='
\c - teacher_user
SELECT current_user;
SELECT * FROM students ORDER BY id;                            -- разрешено
UPDATE students SET scholarship = 55000 WHERE id = 1;          -- разрешено
SELECT * FROM students WHERE id = 1;
INSERT INTO students (full_name, group_name, email, scholarship)
VALUES ('Новый Студент', 'IT-24', 'new@mail.ru', 40000);       -- разрешено (пока есть INSERT)
DELETE FROM students WHERE id = 1;                             -- запрещено
CREATE USER hacker WITH PASSWORD 'Hacker_123!';                -- запрещено

\echo '=================== Задание 4. Минимальные привилегии: REVOKE INSERT ==================='
\c - postgres
REVOKE INSERT ON students FROM teacher_user;
REVOKE USAGE ON SEQUENCE students_id_seq FROM teacher_user;

\c - teacher_user
SELECT current_user;
INSERT INTO students (full_name, group_name) VALUES ('Ещё один', 'IT-24');  -- теперь запрещено
UPDATE students SET scholarship = 52000 WHERE id = 2;          -- по-прежнему разрешено

\echo '=================== Проверка администратора ==================='
\c - db_admin
SELECT current_user;
DELETE FROM students WHERE full_name = 'Новый Студент';        -- разрешено
CREATE USER temp_user WITH PASSWORD 'Temp_Strong_123!';        -- разрешено
SELECT usename FROM pg_user WHERE usename = 'temp_user';
DROP USER temp_user;                                           -- удаление учётной записи
SELECT count(*) AS temp_user_left FROM pg_user WHERE usename = 'temp_user';

\echo '=================== Аутентификация по паролю (TCP) ==================='
\echo '--- неверный пароль:'
\! PGPASSWORD='WrongPassword' psql -h localhost -U student_user -d university -Atc 'SELECT current_user' 2>&1
\echo '--- верный пароль:'
\! PGPASSWORD='Student_Strong_123!' psql -h localhost -U student_user -d university -Atc 'SELECT current_user' 2>&1

\echo '=================== Задание 5. Блокировка пользователя ==================='
\c - postgres
ALTER USER student_user NOLOGIN;
SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'student_user';
\echo '--- попытка входа заблокированного пользователя:'
\! PGPASSWORD='Student_Strong_123!' psql -h localhost -U student_user -d university -Atc 'SELECT current_user' 2>&1
ALTER USER student_user LOGIN;
SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'student_user';
\echo '--- вход после разблокировки:'
\! PGPASSWORD='Student_Strong_123!' psql -h localhost -U student_user -d university -Atc 'SELECT current_user' 2>&1

\echo '=================== Итоговое задание. analyst_user ==================='
\c - analyst_user
SELECT current_user;
SELECT * FROM students ORDER BY id;                            -- разрешено
UPDATE students SET scholarship = 60000 WHERE id = 1;          -- запрещено
DELETE FROM students WHERE id = 1;                             -- запрещено
CREATE USER hacker WITH PASSWORD 'Hacker_123!';                -- запрещено

\echo '=================== Итоговая матрица прав (по данным СУБД) ==================='
\c - postgres
SELECT u AS "user",
       has_table_privilege(u, 'students', 'SELECT') AS "select",
       has_table_privilege(u, 'students', 'INSERT') AS "insert",
       has_table_privilege(u, 'students', 'UPDATE') AS "update",
       has_table_privilege(u, 'students', 'DELETE') AS "delete",
       (SELECT rolsuper OR rolcreaterole FROM pg_roles WHERE rolname = u) AS manage_users
FROM unnest(ARRAY['student_user', 'teacher_user', 'db_admin', 'analyst_user']) AS u;

SELECT * FROM students ORDER BY id;
