-- Таблицы
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    group_name VARCHAR(50),
    email VARCHAR(100)
);
CREATE TABLE teachers (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    department VARCHAR(100)
);
CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    group_name VARCHAR(50),
    specialty VARCHAR(100)
);
CREATE TABLE grades (
    id SERIAL PRIMARY KEY,
    student_id INT,
    teacher_id INT,
    subject VARCHAR(100),
    grade INT
);
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    student_id INT,
    amount DECIMAL(10,2),
    payment_date DATE
);
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    report_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100),
    role_name VARCHAR(50)
);

INSERT INTO students (full_name, group_name, email) VALUES
    ('Иванов Иван', 'IT-23', 'ivanov@mail.ru'),
    ('Петров Петр', 'IT-23', 'petrov@mail.ru');
INSERT INTO teachers (full_name, department) VALUES ('Ким Сергей', 'Информационные технологии');
INSERT INTO groups (group_name, specialty) VALUES ('IT-23', 'Информационные системы');
INSERT INTO grades (student_id, teacher_id, subject, grade) VALUES (1, 1, 'Базы данных', 85), (2, 1, 'Базы данных', 70);
INSERT INTO payments (student_id, amount, payment_date) VALUES (1, 150000, '2026-09-01');
INSERT INTO reports (report_name) VALUES ('Успеваемость за семестр');
INSERT INTO users (username, role_name) VALUES ('student01', 'student_role'), ('teacher01', 'teacher_role');

-- Задание 2. Роли
CREATE ROLE student_role;
CREATE ROLE teacher_role;
CREATE ROLE accountant_role;
CREATE ROLE dean_role;
CREATE ROLE analyst_role;
CREATE ROLE admin_role;

-- Доп. задание. Пользователи
CREATE USER student01    WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher01    WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER accountant01 WITH PASSWORD 'Accountant_Strong_123!';
CREATE USER dean01       WITH PASSWORD 'Dean_Strong_123!';
CREATE USER analyst01    WITH PASSWORD 'Analyst_Strong_123!';

-- Задание 3. Права ролям
GRANT SELECT ON students TO student_role;
GRANT SELECT ON grades TO student_role;

GRANT SELECT ON students TO teacher_role;
GRANT SELECT ON teachers TO teacher_role;
GRANT SELECT ON groups TO teacher_role;
GRANT SELECT, INSERT, UPDATE ON grades TO teacher_role;

GRANT SELECT, INSERT, UPDATE ON payments TO accountant_role;

GRANT SELECT ON students TO dean_role;
GRANT SELECT ON teachers TO dean_role;
GRANT SELECT ON groups TO dean_role;
GRANT SELECT, INSERT, UPDATE ON grades TO dean_role;
GRANT SELECT, INSERT, UPDATE ON reports TO dean_role;

GRANT SELECT ON students TO analyst_role;
GRANT SELECT ON grades TO analyst_role;
GRANT SELECT ON payments TO analyst_role;
GRANT SELECT ON reports TO analyst_role;

-- INSERT в таблицу с SERIAL требует права на последовательность
GRANT USAGE ON SEQUENCE grades_id_seq TO teacher_role, dean_role;
GRANT USAGE ON SEQUENCE payments_id_seq TO accountant_role;
GRANT USAGE ON SEQUENCE reports_id_seq TO dean_role;

GRANT ALL ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO admin_role;

-- Задание 4. Назначение ролей пользователям
GRANT student_role TO student01;
GRANT teacher_role TO teacher01;
GRANT accountant_role TO accountant01;
GRANT dean_role TO dean01;
GRANT analyst_role TO analyst01;

-- Задание 5. Иерархия ролей
CREATE ROLE employee_role;
GRANT SELECT ON students TO employee_role;
CREATE ROLE senior_employee_role;
GRANT employee_role TO senior_employee_role;
GRANT SELECT ON teachers TO senior_employee_role;
GRANT SELECT ON groups TO senior_employee_role;
