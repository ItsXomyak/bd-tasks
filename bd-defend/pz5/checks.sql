\echo === Задание 2. Роли ===
\du
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

\echo === Задание 7. Студент ===
\c university student01
SELECT * FROM students;
UPDATE students SET full_name = 'Test Student' WHERE id = 1;
UPDATE grades SET grade = 100 WHERE id = 1;

\echo === Задание 7. Преподаватель ===
\c university teacher01
SELECT * FROM students;
UPDATE grades SET grade = 90 WHERE id = 1;
DELETE FROM grades WHERE id = 1;
SELECT * FROM payments;

\echo === Задание 7. Бухгалтер ===
\c university accountant01
SELECT * FROM payments;
UPDATE payments SET amount = 160000 WHERE id = 1;
UPDATE grades SET grade = 100 WHERE id = 1;

\echo === Задание 7. Деканат ===
\c university dean01
SELECT * FROM reports;
INSERT INTO reports (report_name) VALUES ('Отчёт деканата');
SELECT * FROM payments;

\echo === Задание 7. Аналитик ===
\c university analyst01
SELECT * FROM payments;
UPDATE payments SET amount = 0 WHERE id = 1;
DELETE FROM students WHERE id = 1;

\echo === Задание 5. Иерархия: senior_employee_role наследует employee_role ===
\c university postgres
SET ROLE senior_employee_role;
SELECT * FROM students;
SELECT * FROM teachers;
SELECT * FROM payments;
RESET ROLE;
SET ROLE employee_role;
SELECT * FROM students;
SELECT * FROM teachers;
RESET ROLE;

\echo === Итоговая матрица ===
SELECT grantee, table_name, string_agg(privilege_type, ',' ORDER BY privilege_type) AS privs
FROM information_schema.role_table_grants
WHERE grantee LIKE '%_role' AND grantee <> 'admin_role'
GROUP BY grantee, table_name ORDER BY grantee, table_name;
