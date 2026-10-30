\echo ==== ЗАДАНИЕ 1. Настройки сервера ====
SHOW ssl;
SHOW config_file;
SHOW hba_file;
SHOW ssl_cert_file;
SHOW ssl_key_file;

\echo ==== ЗАДАНИЕ 2. Текущее соединение (exec внутри контейнера = unix socket, без TLS) ====
SELECT a.pid, a.usename, a.datname, a.client_addr, s.ssl, s.version, s.cipher, s.bits
FROM pg_stat_activity a JOIN pg_stat_ssl s ON a.pid = s.pid
WHERE a.pid = pg_backend_pid();

\echo ==== ЗАДАНИЕ 2. То же по TCP с sslmode=disable ====
\! psql "host=localhost dbname=university user=postgres sslmode=disable" -c "SELECT a.pid, a.client_addr, s.ssl, s.version, s.cipher, s.bits FROM pg_stat_activity a JOIN pg_stat_ssl s ON a.pid=s.pid WHERE a.pid=pg_backend_pid();"

\echo ==== ЗАДАНИЕ 2. То же по TCP с sslmode=require ====
\! psql "host=localhost dbname=university user=postgres sslmode=require" -c "SELECT a.pid, a.client_addr, s.ssl, s.version, s.cipher, s.bits FROM pg_stat_activity a JOIN pg_stat_ssl s ON a.pid=s.pid WHERE a.pid=pg_backend_pid();"

\echo ==== ЗАДАНИЕ 3. verify-full с правильным корневым сертификатом (CN=localhost) ====
\! psql "host=localhost dbname=university user=postgres sslmode=verify-full sslrootcert=/certs/server.crt" -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid=pg_backend_pid();"

\echo ==== ЗАДАНИЕ 3. verify-full с неверным именем сервера (127.0.0.1 вместо localhost) ====
\! psql "host=127.0.0.1 dbname=university user=postgres sslmode=verify-full sslrootcert=/certs/server.crt" -c "SELECT 1;"

\echo ==== ЗАДАНИЕ 3. verify-ca без sslrootcert ====
\! psql "host=localhost dbname=university user=postgres sslmode=verify-ca" -c "SELECT 1;"

\echo ==== ЗАДАНИЕ 4. Правила pg_hba.conf ====
SELECT line_number, type, database, user_name, address, netmask, auth_method, error
FROM pg_hba_file_rules;

\echo ==== Сертификат сервера ====
\! openssl x509 -in /certs/server.crt -noout -subject -issuer -dates
