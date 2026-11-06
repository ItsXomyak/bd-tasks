\echo ==== ЗАДАНИЕ 1. Исходная база university_backup ====
\c university_backup
\dt
SELECT COUNT(*) AS students FROM students;
SELECT COUNT(*) AS grades FROM grades;
SELECT * FROM students;
SELECT * FROM grades;

\echo ==== ЗАДАНИЕ 2. Резервные копии (pg_dump) ====
\! pg_dump -U postgres -d university_backup -F c -f /backups/university_backup.dump && echo "custom dump OK"
\! pg_dump -U postgres -d university_backup -F p -f /backups/university_backup.sql && echo "plain sql OK"
\! ls -l /backups
\echo ---- pg_restore -l (список объектов в custom-архиве) ----
\! pg_restore -l /backups/university_backup.dump
\echo ---- начало university_backup.sql ----
\! grep -v '^--' /backups/university_backup.sql | grep -v '^$' | head -30
\echo ---- university_backup.dump бинарный ----
\! head -c 5 /backups/university_backup.dump | od -c | head -1

\echo ==== ЗАДАНИЕ 3. Восстановление в university_restore ====
CREATE DATABASE university_restore;
\! pg_restore -U postgres -d university_restore /backups/university_backup.dump && echo "pg_restore OK"
\c university_restore
\dt
SELECT COUNT(*) AS students FROM students;
SELECT COUNT(*) AS grades FROM grades;
SELECT * FROM students;
SELECT * FROM grades;
\echo ---- связь таблиц ----
SELECT s.full_name, s.group_name, g.subject, g.grade
FROM students AS s JOIN grades AS g ON s.student_id = g.student_id;

\echo ==== Доп. восстановление SQL-дампа через psql в university_restore_sql ====
CREATE DATABASE university_restore_sql;
\! psql -U postgres -d university_restore_sql -q -f /backups/university_backup.sql && echo "psql restore OK"
\! psql -U postgres -d university_restore_sql -c "SELECT (SELECT COUNT(*) FROM students) AS students, (SELECT COUNT(*) FROM grades) AS grades;"

\echo ==== Задание 4. pg_dumpall (весь кластер) ====
\! pg_dumpall -U postgres -f /backups/all_databases.sql && ls -l /backups/all_databases.sql && grep -c 'CREATE DATABASE' /backups/all_databases.sql
