\echo === Задание 3. Студент ===
\c university student_user
SELECT * FROM students;
UPDATE students SET scholarship = 100000 WHERE id = 1;
DELETE FROM students WHERE id = 1;
CREATE USER hacker WITH PASSWORD 'x';

\echo === Задание 3. Преподаватель ===
\c university teacher_user
SELECT * FROM students;
UPDATE students SET scholarship = 55000 WHERE id = 1;
SELECT * FROM students WHERE id = 1;
DELETE FROM students WHERE id = 1;
CREATE USER hacker WITH PASSWORD 'x';
INSERT INTO students (full_name, group_name) VALUES ('Тест', 'IT-25');

\echo === Задание 3. Админ ===
\c university db_admin
SELECT * FROM students;
CREATE USER tmp_user WITH PASSWORD 'x';
DROP USER tmp_user;

\echo === Задание 5. Блокировка студента ===
ALTER USER student_user NOLOGIN;
\! psql -U student_user -d university -c "SELECT 1" ; true
ALTER USER student_user LOGIN;
\! psql -U student_user -d university -c "SELECT current_user"

\echo === Итоговое. Аналитик ===
\c university analyst_user
SELECT * FROM students;
UPDATE students SET scholarship = 60000 WHERE id = 1;
DELETE FROM students WHERE id = 1;
CREATE USER hacker WITH PASSWORD 'x';

\c university postgres
\dp students
\du
