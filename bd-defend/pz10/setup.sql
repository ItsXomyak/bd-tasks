-- Задание 1. Учебная база
CREATE DATABASE university_backup;
\c university_backup

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    group_name VARCHAR(20),
    email VARCHAR(100),
    enrollment_year INTEGER
);

CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    subject VARCHAR(100),
    grade INTEGER CHECK (grade BETWEEN 2 AND 5)
);

INSERT INTO students (full_name, group_name, email, enrollment_year) VALUES
('Иванов Иван', 'IT-101', 'ivanov@mail.com', 2025),
('Петров Петр', 'IT-102', 'petrov@mail.com', 2025),
('Сидорова Анна', 'IT-101', 'sidorova@mail.com', 2024),
('Ким Алексей', 'IT-103', 'kim@mail.com', 2025),
('Ахметова Дана', 'IT-102', 'akhmetova@mail.com', 2024);

INSERT INTO grades (student_id, subject, grade) VALUES
(1, 'Базы данных', 5),
(2, 'Базы данных', 4),
(3, 'Защита баз данных', 5),
(4, 'Защита баз данных', 3),
(5, 'Программирование', 4);
