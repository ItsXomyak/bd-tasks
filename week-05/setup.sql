-- Неделя 5. ПЗ №5: ролевая модель управления доступом (RBAC)
-- Выполняется от имени postgres в базе university

-- Таблицы
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

CREATE TABLE groups (
    id         SERIAL PRIMARY KEY,
    group_name VARCHAR(50),
    specialty  VARCHAR(100)
);

CREATE TABLE grades (
    id         SERIAL PRIMARY KEY,
    student_id INT,
    teacher_id INT,
    subject    VARCHAR(100),
    grade      INT
);

CREATE TABLE payments (
    id           SERIAL PRIMARY KEY,
    student_id   INT,
    amount       DECIMAL(10,2),
    payment_date DATE
);

CREATE TABLE reports (
    id          SERIAL PRIMARY KEY,
    report_name VARCHAR(100),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id        SERIAL PRIMARY KEY,
    username  VARCHAR(100),
    role_name VARCHAR(50)
);

-- Тестовые данные (в методичке не заданы)
INSERT INTO students (full_name, group_name, email) VALUES
    ('Иванов Иван',   'IT-23', 'ivanov@mail.ru'),
    ('Петров Петр',   'IT-23', 'petrov@mail.ru'),
    ('Сидорова Анна', 'IT-24', 'sidorova@mail.ru');

INSERT INTO teachers (full_name, department) VALUES
    ('Ким Сергей',    'Информационные технологии'),
    ('Ахметова Алия', 'Компьютерные науки');

INSERT INTO groups (group_name, specialty) VALUES
    ('IT-23', 'Информационные системы'),
    ('IT-24', 'Программная инженерия');

INSERT INTO grades (student_id, teacher_id, subject, grade) VALUES
    (1, 1, 'Базы данных',      90),
    (2, 1, 'Базы данных',      85),
    (3, 2, 'Программирование', 95);

INSERT INTO payments (student_id, amount, payment_date) VALUES
    (1, 250000, '2026-09-01'),
    (2, 250000, '2026-09-03'),
    (3, 125000, '2026-09-10');

INSERT INTO reports (report_name) VALUES
    ('Успеваемость за сентябрь'),
    ('Оплата обучения за осенний семестр');

INSERT INTO users (username, role_name) VALUES
    ('student01',    'student_role'),
    ('teacher01',    'teacher_role'),
    ('accountant01', 'accountant_role'),
    ('dean01',       'dean_role'),
    ('analyst01',    'analyst_role'),
    ('admin01',      'admin_role');

-- Задание 2. Роли
CREATE ROLE student_role;
CREATE ROLE teacher_role;
CREATE ROLE accountant_role;
CREATE ROLE dean_role;
CREATE ROLE analyst_role;
CREATE ROLE admin_role;

-- Дополнительное задание: пользователи
CREATE USER student01    WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher01    WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER accountant01 WITH PASSWORD 'Accountant_Strong_123!';
CREATE USER dean01       WITH PASSWORD 'Dean_Strong_123!';
CREATE USER analyst01    WITH PASSWORD 'Analyst_Strong_123!';
-- администратора добавил сам, чтобы роль admin_role не была пустой
CREATE USER admin01      WITH PASSWORD 'Admin_Strong_123!' CREATEROLE;

-- Задание 3. Права назначаются ролям
-- 3.1 студент
GRANT SELECT ON students, grades TO student_role;

-- 3.2 преподаватель (без DELETE)
GRANT SELECT ON students, teachers, groups TO teacher_role;
GRANT SELECT, INSERT, UPDATE ON grades TO teacher_role;
GRANT USAGE ON SEQUENCE grades_id_seq TO teacher_role;

-- 3.3 бухгалтер (только платежи)
GRANT SELECT, INSERT, UPDATE ON payments TO accountant_role;
GRANT USAGE ON SEQUENCE payments_id_seq TO accountant_role;

-- 3.4 деканат
GRANT SELECT ON students, teachers, groups TO dean_role;
GRANT SELECT, INSERT, UPDATE ON grades, reports TO dean_role;
GRANT USAGE ON SEQUENCE grades_id_seq, reports_id_seq TO dean_role;

-- 3.5 аналитик (только чтение)
GRANT SELECT ON students, grades, payments, reports TO analyst_role;

-- 3.6 администратор (все объекты схемы)
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;

-- Задание 4. Роли назначаются пользователям
GRANT student_role    TO student01;
GRANT teacher_role    TO teacher01;
GRANT accountant_role TO accountant01;
GRANT dean_role       TO dean01;
GRANT analyst_role    TO analyst01;
GRANT admin_role      TO admin01;

-- Задание 5. Иерархия ролей
CREATE ROLE employee_role;
GRANT SELECT ON students TO employee_role;

CREATE ROLE senior_employee_role;
GRANT employee_role TO senior_employee_role;
GRANT SELECT ON teachers, groups TO senior_employee_role;

-- пользователи для проверки иерархии
CREATE USER employee01 WITH PASSWORD 'Employee_Strong_123!';
CREATE USER senior01   WITH PASSWORD 'Senior_Strong_123!';
GRANT employee_role        TO employee01;
GRANT senior_employee_role TO senior01;
