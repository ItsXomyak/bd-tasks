-- Неделя 6. Проверки к ПЗ №6
-- Запуск: docker compose exec db psql -U postgres -d university -f /checks.sql
\set ON_ERROR_STOP 0
\set ECHO queries
\pset footer off

\echo '=================== Задание 1. Исходные данные (postgres) ==================='
SELECT * FROM students ORDER BY id;
SELECT * FROM grades ORDER BY id;

\echo '=================== Задание 2. Права на столбцы: teacher_limited ==================='
SET ROLE teacher_limited;
SELECT current_user;
SELECT id, full_name, group_name FROM students ORDER BY id;      -- разрешено
SELECT scholarship FROM students;                                -- запрещено
SELECT email FROM students;                                      -- запрещено
SELECT * FROM students;                                          -- запрещено (в * есть закрытые столбцы)
UPDATE students SET scholarship = 0 WHERE id = 1;                -- запрещено
RESET ROLE;

\echo '=================== Задание 2. Права на столбцы: accountant_limited ==================='
SET ROLE accountant_limited;
SELECT current_user;
SELECT id, scholarship FROM students ORDER BY id;                -- разрешено
SELECT full_name FROM students;                                  -- запрещено
RESET ROLE;

\echo '--- какие столбцы кому доступны'
SELECT grantee, column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_name = 'students' AND grantee IN ('teacher_limited', 'accountant_limited')
ORDER BY grantee, column_name;

\echo '=================== Задание 3. Представление student_public_info ==================='
SET ROLE teacher_limited;
SELECT * FROM student_public_info ORDER BY id;                   -- разрешено, 3 столбца
RESET ROLE;

\echo '--- Часть В. Отзываем прямой доступ к таблице students'
REVOKE SELECT ON students FROM teacher_limited;

SELECT grantee, column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_name = 'students' AND grantee = 'teacher_limited';

SET ROLE teacher_limited;
SELECT id, full_name, group_name FROM students;                  -- теперь запрещено
SELECT scholarship FROM students;                                -- запрещено
SELECT * FROM student_public_info ORDER BY id;                   -- по-прежнему разрешено
RESET ROLE;

\echo '=================== Задание 5. Проверка 1: teacher01 ==================='
\c - teacher01
SELECT current_user;
SELECT * FROM grades ORDER BY id;                                -- только свои строки
UPDATE grades SET grade = 95 WHERE id = 1;                       -- своя строка: UPDATE 1
UPDATE grades SET grade = 100 WHERE id = 3;                      -- чужая строка: UPDATE 0
UPDATE grades SET teacher_username = 'teacher02' WHERE id = 1;   -- отдать свою строку: WITH CHECK
DELETE FROM grades WHERE id = 1;                                 -- запрещено: нет DELETE
INSERT INTO grades (student_id, teacher_username, subject, grade)
VALUES (3, 'teacher01', 'Базы данных', 100);                     -- запрещено: нет INSERT
SELECT * FROM students;                                          -- запрещено

\echo '=================== Задание 5. Проверка 2: teacher02 ==================='
\c - teacher02
SELECT current_user;
SELECT * FROM grades ORDER BY id;                                -- только свои строки, id=3 не изменён
UPDATE grades SET grade = 50 WHERE id = 1;                       -- чужая строка: UPDATE 0

\echo '=================== Задание 5. Проверки 3 и 4: teacher_limited ==================='
\c - postgres
SET ROLE teacher_limited;
SELECT scholarship FROM students;                                -- запрещено
SELECT * FROM student_public_info ORDER BY id;                   -- разрешено
RESET ROLE;

\echo '=================== Итоговое состояние grades (postgres, владелец таблицы) ==================='
SELECT * FROM grades ORDER BY id;

\echo '=================== Доработка: ограничение обновляемых столбцов ==================='
-- преподавателю достаточно менять только оценку
REVOKE UPDATE ON grades FROM teacher_rls_role;
GRANT UPDATE (grade) ON grades TO teacher_rls_role;

\c - teacher01
UPDATE grades SET teacher_username = 'teacher01' WHERE id = 3;   -- запрещено правами на столбцы
UPDATE grades SET subject = 'Другой предмет' WHERE id = 1;       -- запрещено правами на столбцы
UPDATE grades SET grade = 96 WHERE id = 1;                       -- разрешено
SELECT * FROM grades ORDER BY id;

\echo '=================== Политики RLS ==================='
\c - postgres
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'grades';
SELECT policyname, cmd, roles, qual, with_check FROM pg_policies WHERE tablename = 'grades';
