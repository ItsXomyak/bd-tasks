-- Неделя 5. Проверки к ПЗ №5 (RBAC)
-- Запуск: docker compose exec db psql -U postgres -d university -f /checks.sql
\set ON_ERROR_STOP 0
\set ECHO queries
\pset footer off

\echo '=================== Задание 2. Созданные роли ==================='
SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname LIKE '%\_role'
ORDER BY rolname;

\echo '=================== Задание 4. Пользователь -> роль ==================='
SELECT m.rolname AS "user", string_agg(r.rolname, ', ' ORDER BY r.rolname) AS roles
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE m.rolname NOT LIKE 'pg\_%'
GROUP BY m.rolname
ORDER BY m.rolname;

\echo '=================== Задание 7. student01 ==================='
\c - student01
SELECT * FROM students ORDER BY id;                         -- разрешено
SELECT * FROM grades ORDER BY id;                           -- разрешено
UPDATE students SET full_name = 'Test Student' WHERE id = 1; -- запрещено
UPDATE grades SET grade = 100 WHERE id = 1;                 -- запрещено
SELECT * FROM payments;                                     -- запрещено

\echo '=================== Задание 7. teacher01 ==================='
\c - teacher01
SELECT * FROM students ORDER BY id;                         -- разрешено
UPDATE grades SET grade = 90 WHERE id = 1;                  -- разрешено
INSERT INTO grades (student_id, teacher_id, subject, grade)
VALUES (1, 1, 'Операционные системы', 88);                  -- разрешено
DELETE FROM grades WHERE id = 1;                            -- запрещено
SELECT * FROM payments;                                     -- запрещено

\echo '=================== Задание 7. accountant01 ==================='
\c - accountant01
SELECT * FROM payments ORDER BY id;                         -- разрешено
INSERT INTO payments (student_id, amount, payment_date)
VALUES (3, 125000, '2026-10-10');                           -- разрешено
UPDATE grades SET grade = 100 WHERE id = 1;                 -- запрещено
DELETE FROM payments WHERE id = 1;                          -- запрещено

\echo '=================== Задание 7. dean01 ==================='
\c - dean01
SELECT * FROM groups ORDER BY id;                           -- разрешено
INSERT INTO reports (report_name) VALUES ('Отчёт деканата'); -- разрешено
SELECT * FROM payments;                                     -- запрещено

\echo '=================== Задание 7. analyst01 ==================='
\c - analyst01
SELECT * FROM payments ORDER BY id;                         -- разрешено
SELECT id, report_name FROM reports ORDER BY id;            -- разрешено
UPDATE payments SET amount = 0 WHERE id = 1;                -- запрещено
DELETE FROM reports WHERE id = 1;                           -- запрещено

\echo '=================== admin01 ==================='
\c - admin01
SELECT * FROM users ORDER BY id;                            -- разрешено
DELETE FROM reports WHERE report_name = 'Отчёт деканата';   -- разрешено
CREATE USER new_teacher WITH PASSWORD 'NewTeacher_123!';    -- разрешено (CREATEROLE)
DROP USER new_teacher;

\echo '=================== Задание 5. Иерархия ролей ==================='
\c - postgres
SELECT r.rolname AS parent_role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('employee_role', 'senior_employee_role')
ORDER BY 1, 2;

\c - employee01
SELECT id, full_name FROM students ORDER BY id;             -- разрешено (employee_role)
SELECT * FROM teachers;                                     -- запрещено

\c - senior01
SELECT id, full_name FROM students ORDER BY id;             -- разрешено (унаследовано от employee_role)
SELECT * FROM teachers ORDER BY id;                         -- разрешено (senior_employee_role)
SELECT * FROM groups ORDER BY id;                           -- разрешено (senior_employee_role)

\echo '=================== Задание 6. Разделение обязанностей ==================='
\c - postgres
-- имитируем нарушение: администратору дополнительно выдали роль бухгалтера
GRANT accountant_role TO admin01;

-- поиск пользователей с конфликтующими ролями
WITH user_roles AS (
    SELECT m.rolname AS username, r.rolname AS role_name
    FROM pg_auth_members am
    JOIN pg_roles r ON r.oid = am.roleid
    JOIN pg_roles m ON m.oid = am.member
),
conflicts(role1, role2) AS (
    VALUES ('accountant_role', 'admin_role'),
           ('teacher_role',    'student_role'),
           ('analyst_role',    'accountant_role')
)
SELECT a.username, c.role1, c.role2
FROM conflicts c
JOIN user_roles a ON a.role_name = c.role1
JOIN user_roles b ON b.role_name = c.role2 AND b.username = a.username;

-- устраняем нарушение и проверяем ещё раз
REVOKE accountant_role FROM admin01;

SELECT count(*) AS users_with_accountant_and_admin
FROM pg_auth_members a1
JOIN pg_auth_members a2 ON a1.member = a2.member
WHERE a1.roleid = 'accountant_role'::regrole
  AND a2.roleid = 'admin_role'::regrole;

\echo '=================== Итоговая матрица RBAC (по данным СУБД) ==================='
SELECT r AS "role", t AS "table",
       CASE
         WHEN has_table_privilege(r, t, 'SELECT') AND has_table_privilege(r, t, 'INSERT')
          AND has_table_privilege(r, t, 'UPDATE') AND has_table_privilege(r, t, 'DELETE') THEN 'FULL'
         ELSE coalesce(nullif(concat_ws('/',
                CASE WHEN has_table_privilege(r, t, 'SELECT') THEN 'R' END,
                CASE WHEN has_table_privilege(r, t, 'INSERT') THEN 'I' END,
                CASE WHEN has_table_privilege(r, t, 'UPDATE') THEN 'U' END,
                CASE WHEN has_table_privilege(r, t, 'DELETE') THEN 'D' END), ''), '-')
       END AS access,
       k
FROM unnest(ARRAY['student_role', 'teacher_role', 'accountant_role', 'dean_role', 'analyst_role', 'admin_role']) WITH ORDINALITY AS rr(r, n)
CROSS JOIN unnest(ARRAY['students', 'teachers', 'groups', 'grades', 'payments', 'reports', 'users']) WITH ORDINALITY AS tt(t, k)
ORDER BY n, k \crosstabview "role" "table" access k
