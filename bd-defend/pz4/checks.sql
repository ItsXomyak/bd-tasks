\echo === Задание 3. Студент ===
\c university student_user
SELECT * FROM students;
SELECT * FROM grades;
UPDATE grades SET grade = 100 WHERE id = 1;

\echo === Задание 3. Преподаватель ===
\c university teacher_user
SELECT * FROM grades;
UPDATE grades SET grade = 95 WHERE id = 1;
DELETE FROM grades WHERE id = 1;

\echo === Задание 3. Бухгалтер ===
\c university accountant_user
SELECT * FROM payments;
UPDATE payments SET amount = 100000 WHERE id = 1;
SELECT * FROM students;

\echo === Задание 4. REVOKE ===
\c university postgres
GRANT DELETE ON grades TO teacher_user;
\c university teacher_user
DELETE FROM grades WHERE id = 3;
\c university postgres
REVOKE DELETE ON grades FROM teacher_user;
INSERT INTO grades (student_id, subject, grade) VALUES (3, 'Программирование', 95);
\c university teacher_user
DELETE FROM grades WHERE id = 1;

\echo === Задание 5. Роли ===
\c university postgres
\du
SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants
WHERE grantee LIKE '%_role' ORDER BY grantee, table_name, privilege_type;

\echo === Задание 6. Лишние права преподавателя ===
\c university teacher_user
DELETE FROM students WHERE id = 1;
DROP TABLE students;
CREATE USER test_user WITH PASSWORD 'Test_123!';

\echo === Задание 7. Аналитик ===
\c university analyst_user
SELECT * FROM students;
SELECT * FROM payments;
UPDATE students SET group_name = 'IT-25' WHERE id = 1;

\echo === Итог. Админ ===
\c university db_admin
SELECT * FROM students;
INSERT INTO students (full_name, group_name, email) VALUES ('Тест Тестов', 'IT-25', 't@mail.ru');
UPDATE students SET group_name = 'IT-26' WHERE full_name = 'Тест Тестов';
DELETE FROM students WHERE full_name = 'Тест Тестов';

\echo === Итог. INSERT у всех ===
\c university student_user
INSERT INTO students (full_name) VALUES ('x');
\c university teacher_user
INSERT INTO grades (student_id, subject, grade) VALUES (1, 'x', 1);
\c university accountant_user
INSERT INTO payments (student_id, amount) VALUES (1, 1);
\c university analyst_user
INSERT INTO students (full_name) VALUES ('x');
