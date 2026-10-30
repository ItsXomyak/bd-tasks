-- Включаем TLS (вступит в силу при старте основного сервера, после initdb)
ALTER SYSTEM SET ssl = on;

CREATE USER app_user WITH PASSWORD 'App_Strong_123!';
GRANT CONNECT ON DATABASE university TO app_user;
