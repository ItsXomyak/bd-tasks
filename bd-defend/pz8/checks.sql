\echo === Этап 1. Открытое хранение ===
SELECT * FROM students_security;

\echo === Этап 2. pgcrypto ===
SELECT extname, extversion FROM pg_extension WHERE extname = 'pgcrypto';
SELECT encode(pgp_sym_encrypt('TEST-123', 'class-demo-key'), 'hex') AS encrypted_value;
\echo --- та же строка второй раз: другой шифротекст (случайная соль)
SELECT encode(pgp_sym_encrypt('TEST-123', 'class-demo-key'), 'hex') AS encrypted_value;

\echo === Этап 3. Зашифрованная таблица ===
SELECT id, student_name, encode(encrypted_document, 'hex') AS encrypted_value FROM students_encrypted;
SELECT id, student_name, length(encrypted_document) AS bytes FROM students_encrypted;

\echo === Этап 4. Расшифрование ===
SELECT id, student_name, pgp_sym_decrypt(encrypted_document, 'class-demo-key') AS document_number
FROM students_encrypted;

\echo --- неверная парольная фраза
SELECT pgp_sym_decrypt(encrypted_document, 'incorrect-demo-key') FROM students_encrypted;

\echo === Этап 5. Сравнение ===
SELECT student_name, document_number FROM students_security;
SELECT student_name, encode(encrypted_document, 'hex') AS encrypted_document FROM students_encrypted;

\echo --- поиск по значению: открытое хранение
SELECT * FROM students_security WHERE document_number = 'DOC-1002';
\echo --- поиск по значению: шифрованное хранение (только через расшифровку каждой строки)
SELECT id, student_name FROM students_encrypted
WHERE pgp_sym_decrypt(encrypted_document, 'class-demo-key') = 'DOC-1002';
\echo --- сравнение шифротекста напрямую не работает (соль разная)
SELECT count(*) FROM students_encrypted
WHERE encrypted_document = pgp_sym_encrypt('DOC-1002', 'class-demo-key');
