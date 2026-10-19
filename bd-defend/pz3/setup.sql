-- Таблица и данные
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    group_name VARCHAR(50),
    email VARCHAR(100),
    scholarship DECIMAL(10,2)
);

INSERT INTO students (full_name, group_name, email, scholarship) VALUES
    ('Иванов Иван',  'IT-23', 'ivanov@mail.ru',   50000),
    ('Петров Петр',  'IT-23', 'petrov@mail.ru',   45000),
    ('Сидорова Анна','IT-24', 'sidorova@mail.ru', 50000);

-- Задание 1. Пользователи
CREATE USER student_user WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher_user WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER db_admin     WITH PASSWORD 'Admin_Strong_123!';

SELECT usename FROM pg_user;

-- Задание 2. Права
GRANT CONNECT ON DATABASE university TO student_user;
GRANT USAGE ON SCHEMA public TO student_user;
GRANT SELECT ON students TO student_user;

GRANT CONNECT ON DATABASE university TO teacher_user;
GRANT USAGE ON SCHEMA public TO teacher_user;
GRANT SELECT, INSERT, UPDATE ON students TO teacher_user;

ALTER USER db_admin WITH SUPERUSER;

-- Задание 4. Минимальные привилегии: преподавателю INSERT не нужен
REVOKE INSERT ON students FROM teacher_user;

-- Итоговое задание. Аналитик: только чтение
CREATE USER analyst_user WITH PASSWORD 'Analyst_Strong_123!';
GRANT CONNECT ON DATABASE university TO analyst_user;
GRANT USAGE ON SCHEMA public TO analyst_user;
GRANT SELECT ON students TO analyst_user;
