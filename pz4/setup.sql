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
CREATE TABLE grades (
    id SERIAL PRIMARY KEY,
    student_id INT,
    subject VARCHAR(100),
    grade INT
);
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    student_id INT,
    amount DECIMAL(10,2),
    payment_date DATE
);

INSERT INTO students (full_name, group_name, email) VALUES
    ('Иванов Иван', 'IT-23', 'ivanov@mail.ru'),
    ('Петров Петр', 'IT-23', 'petrov@mail.ru'),
    ('Сидорова Анна', 'IT-24', 'sidorova@mail.ru');
INSERT INTO teachers (full_name, department) VALUES
    ('Ким Сергей', 'Информационные технологии'),
    ('Ахметова Алия', 'Компьютерные науки');
INSERT INTO grades (student_id, subject, grade) VALUES
    (1, 'Базы данных', 90),
    (2, 'Базы данных', 85),
    (3, 'Программирование', 95);
INSERT INTO payments (student_id, amount, payment_date) VALUES
    (1, 150000, '2026-09-01'),
    (2, 150000, '2026-09-03');

-- Задание 1. Пользователи
CREATE USER student_user    WITH PASSWORD 'Student_123!';
CREATE USER teacher_user    WITH PASSWORD 'Teacher_123!';
CREATE USER accountant_user WITH PASSWORD 'Accountant_123!';
CREATE USER db_admin        WITH PASSWORD 'Admin_123!';

-- Задание 3. GRANT
GRANT SELECT ON students, grades TO student_user;

GRANT SELECT ON students, teachers, grades TO teacher_user;
GRANT UPDATE ON grades TO teacher_user;

GRANT SELECT, UPDATE ON payments TO accountant_user;

GRANT ALL ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO db_admin;

-- Задание 5. Роли
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

-- Задание 7. Аналитик
CREATE ROLE analyst_role;
GRANT SELECT ON students, grades, payments TO analyst_role;
CREATE USER analyst_user WITH PASSWORD 'Analyst_123!';
GRANT analyst_role TO analyst_user;
