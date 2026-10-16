-- Неделя 3. ПЗ №3: пользователи, аутентификация, права доступа
-- Выполняется от имени postgres в базе university

-- Подготовка: таблица и тестовые данные
CREATE TABLE students (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100),
    group_name  VARCHAR(50),
    email       VARCHAR(100),
    scholarship DECIMAL(10,2)
);

INSERT INTO students (full_name, group_name, email, scholarship) VALUES
    ('Иванов Иван',   'IT-23', 'ivanov@mail.ru',   50000),
    ('Петров Петр',   'IT-23', 'petrov@mail.ru',   45000),
    ('Сидорова Анна', 'IT-24', 'sidorova@mail.ru', 50000);

-- Задание 1. Создание пользователей (аутентификация по паролю)
CREATE USER student_user WITH PASSWORD 'Student_Strong_123!';
CREATE USER teacher_user WITH PASSWORD 'Teacher_Strong_123!';
CREATE USER db_admin     WITH PASSWORD 'Admin_Strong_123!';

-- Задание 2. Настройка прав
-- студент: только чтение
GRANT CONNECT ON DATABASE university TO student_user;
GRANT USAGE   ON SCHEMA public       TO student_user;
GRANT SELECT  ON students            TO student_user;

-- преподаватель: чтение, добавление, изменение
GRANT CONNECT ON DATABASE university         TO teacher_user;
GRANT USAGE   ON SCHEMA public               TO teacher_user;
GRANT SELECT, INSERT, UPDATE ON students     TO teacher_user;
GRANT USAGE   ON SEQUENCE students_id_seq    TO teacher_user;  -- нужно для INSERT в SERIAL

-- администратор: расширенные полномочия (учебная лаборатория)
ALTER USER db_admin WITH SUPERUSER;

-- Итоговое задание. Аналитик: подключение + только чтение
CREATE USER analyst_user WITH PASSWORD 'Analyst_Strong_123!';
GRANT CONNECT ON DATABASE university TO analyst_user;
GRANT USAGE   ON SCHEMA public       TO analyst_user;
GRANT SELECT  ON students            TO analyst_user;

-- Отбираем у PUBLIC право подключаться ко всем БД по умолчанию,
-- чтобы CONNECT был только у тех, кому мы его явно выдали
REVOKE CONNECT ON DATABASE university FROM PUBLIC;
