DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS copies;

CREATE TABLE copies (
    title_id  INT PRIMARY KEY REFERENCES titles(title_id),
    available INT NOT NULL CHECK (available >= 0)
);

CREATE TABLE loans (
    loan_id   SERIAL PRIMARY KEY,
    title_id  INT NOT NULL REFERENCES titles(title_id),
    reader    TEXT NOT NULL,
    loaned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO copies (title_id, available)
SELECT title_id, 100 FROM titles ORDER BY title_id LIMIT 10;
