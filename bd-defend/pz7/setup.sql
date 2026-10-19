-- Этап 1. Таблица пользователей
CREATE TABLE app_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL
);

INSERT INTO app_users (username, full_name) VALUES
    ('student01', 'Иван Петров'),
    ('student02', 'Анна Сидорова'),
    ('teacher01', 'Мария Иванова');

SELECT id, username, full_name FROM app_users;

-- Этап 5. Приложение подключается не админом, а пользователем с минимальными правами
CREATE USER app_user WITH PASSWORD 'App_Strong_123!';
GRANT CONNECT ON DATABASE university TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT ON app_users TO app_user;
