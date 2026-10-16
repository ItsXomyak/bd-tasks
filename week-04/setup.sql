-- Неделя 4. ПЗ №4: авторизация и разграничение прав доступа
-- Выполняется от имени postgres в базе university

-- 1. Таблицы и тестовые данные
CREATE TABLE students (
    id         SERIAL PRIMARY KEY,
    full_name  VARCHAR(100),
    group_name VARCHAR(50),
    email      VARCHAR(100)
);

CREATE TABLE teachers (
    id         SERIAL PRIMARY KEY,
    full_name  VARCHAR(100),
    department VARCHAR(100)
);

CREATE TABLE grades (
    id         SERIAL PRIMARY KEY,
    student_id INT,
    subject    VARCHAR(100),
    grade      INT
);

CREATE TABLE payments (
    id           SERIAL PRIMARY KEY,
    student_id   INT,
    amount       DECIMAL(10,2),
    payment_date DATE
);

INSERT INTO students (full_name, group_name, email) VALUES
    ('Иванов Иван',   'IT-23', 'ivanov@mail.ru'),
    ('Петров Петр',   'IT-23', 'petrov@mail.ru'),
    ('Сидорова Анна', 'IT-24', 'sidorova@mail.ru');

INSERT INTO teachers (full_name, department) VALUES
    ('Ким Сергей',    'Информационные технологии'),
    ('Ахметова Алия', 'Компьютерные науки');

INSERT INTO grades (student_id, subject, grade) VALUES
    (1, 'Базы данных',      90),
    (2, 'Базы данных',      85),
    (3, 'Программирование', 95);

-- в методичке платежи не заполнены; добавил, чтобы было что проверять бухгалтеру
INSERT INTO payments (student_id, amount, payment_date) VALUES
    (1, 250000, '2026-09-01'),
    (2, 250000, '2026-09-03'),
    (3, 125000, '2026-09-10');

-- Задание 1. Пользователи
CREATE USER student_user    WITH PASSWORD 'Student_123!';
CREATE USER teacher_user    WITH PASSWORD 'Teacher_123!';
CREATE USER accountant_user WITH PASSWORD 'Accountant_123!';
CREATE USER db_admin        WITH PASSWORD 'Admin_123!';

-- Задание 2. Матрица доступа (см. report.md):
--              students  teachers  grades  payments
-- Student      R         -         R       -
-- Teacher      R         R         R/U     -
-- Accountant   -         -         -       R/U
-- Admin        R/C/U/D   R/C/U/D   R/C/U/D R/C/U/D

-- Задание 3. Прямая выдача прав пользователям (GRANT)
GRANT SELECT ON students, grades TO student_user;

GRANT SELECT ON students, teachers, grades TO teacher_user;
GRANT UPDATE ON grades TO teacher_user;

GRANT SELECT, UPDATE ON payments TO accountant_user;

-- администратор: полный доступ к данным + право управлять ролями (не суперпользователь)
GRANT SELECT, INSERT, UPDATE, DELETE ON students, teachers, grades, payments TO db_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO db_admin;
ALTER USER db_admin CREATEROLE;
