\echo === Проверка 1: teacher01 ===
\c postgres teacher01
SELECT * FROM grades;
UPDATE grades SET grade = 95 WHERE id = 1;
UPDATE grades SET grade = 100 WHERE id = 3;
SELECT * FROM grades;

\echo === Проверка 2: teacher02 ===
\c postgres teacher02
SELECT * FROM grades;

\echo === Проверка 3: teacher_limited, столбцы ===
\c postgres postgres
SET ROLE teacher_limited;
SELECT id, full_name, group_name FROM students;
SELECT scholarship FROM students;
UPDATE students SET scholarship = 0 WHERE id = 1;

\echo === Проверка 4: VIEW ===
SELECT * FROM student_public_info;
SELECT * FROM students;

\echo === Бухгалтер ===
RESET ROLE;
SET ROLE accountant_limited;
SELECT id, scholarship FROM students;
SELECT full_name FROM students;
RESET ROLE;
SELECT * FROM grades;
