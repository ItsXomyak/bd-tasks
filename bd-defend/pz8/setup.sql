-- Этап 1. Открытое хранение
CREATE TABLE students_security (
    id SERIAL PRIMARY KEY,
    student_name TEXT NOT NULL,
    document_number TEXT NOT NULL
);

INSERT INTO students_security (student_name, document_number) VALUES
    ('Иван Петров',     'DOC-1001'),
    ('Анна Сидорова',   'DOC-1002'),
    ('Алексей Смирнов', 'DOC-1003');

-- Этап 2. Расширение
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Этап 3. Зашифрованное хранение
CREATE TABLE students_encrypted (
    id SERIAL PRIMARY KEY,
    student_name TEXT NOT NULL,
    encrypted_document BYTEA NOT NULL
);

INSERT INTO students_encrypted (student_name, encrypted_document) VALUES
    ('Иван Петров',     pgp_sym_encrypt('DOC-1001', 'class-demo-key')),
    ('Анна Сидорова',   pgp_sym_encrypt('DOC-1002', 'class-demo-key')),
    ('Алексей Смирнов', pgp_sym_encrypt('DOC-1003', 'class-demo-key'));
