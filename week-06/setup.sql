-- Неделя 6. ПЗ №6: защита данных на уровне таблиц, столбцов, строк и представлений
-- Выполняется от имени postgres в базе university

-- Задание 1. Учебная база данных
CREATE TABLE students (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    group_name  VARCHAR(50)  NOT NULL,
    email       VARCHAR(100),
    scholarship NUMERIC(10,2)
);

CREATE TABLE grades (
    id               SERIAL PRIMARY KEY,
    student_id       INT  NOT NULL REFERENCES students(id),
    teacher_username TEXT NOT NULL,
    subject          VARCHAR(100) NOT NULL,
    grade            INT  NOT NULL CHECK (grade BETWEEN 0 AND 100)
);

INSERT INTO students (full_name, group_name, email, scholarship) VALUES
    ('Иван Петров',    'IT-21', 'ivan@example.com',    25000),
    ('Анна Садыкова',  'IT-22', 'anna@example.com',    30000),
    ('Данияр Ахметов', 'IT-21', 'daniyar@example.com', 20000),
    ('Мария Иванова',  'IT-23', 'maria@example.com',   28000);

INSERT INTO grades (student_id, teacher_username, subject, grade) VALUES
    (1, 'teacher01', 'Базы данных',       90),
    (2, 'teacher01', 'Базы данных',       85),
    (3, 'teacher02', 'Компьютерные сети', 92),
    (4, 'teacher02', 'Компьютерные сети', 88);

-- Задание 2. Права на таблицы и столбцы
CREATE ROLE teacher_limited;
CREATE ROLE accountant_limited;

-- преподаватель видит только id, ФИО и группу
GRANT SELECT (id, full_name, group_name) ON students TO teacher_limited;

-- бухгалтер видит id и стипендию
GRANT SELECT (id, scholarship) ON students TO accountant_limited;

-- Задание 3. Защищённое представление
CREATE VIEW student_public_info AS
SELECT id, full_name, group_name
FROM students;

GRANT SELECT ON student_public_info TO teacher_limited;

-- Задание 4. Row-Level Security
CREATE ROLE teacher01 LOGIN PASSWORD 'Teacher01_Strong!';
CREATE ROLE teacher02 LOGIN PASSWORD 'Teacher02_Strong!';

CREATE ROLE teacher_rls_role;
GRANT teacher_rls_role TO teacher01;
GRANT teacher_rls_role TO teacher02;

GRANT SELECT, UPDATE ON grades TO teacher_rls_role;

ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

-- чтение: только свои строки
CREATE POLICY grades_select_policy
    ON grades
    FOR SELECT
    TO teacher_rls_role
    USING (teacher_username = current_user);

-- изменение: только свои строки, и новая версия строки тоже должна остаться своей
CREATE POLICY grades_update_policy
    ON grades
    FOR UPDATE
    TO teacher_rls_role
    USING (teacher_username = current_user)
    WITH CHECK (teacher_username = current_user);
