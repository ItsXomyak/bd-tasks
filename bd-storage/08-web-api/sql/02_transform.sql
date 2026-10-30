-- Занятие 2: raw_checkouts -> нормализованные таблицы
INSERT INTO titles (Title, ISBN, Creator, Publisher, PublicationYear)
SELECT DISTINCT Title, ISBN, Creator, Publisher, PublicationYear FROM raw_checkouts;

-- join по всем 5 полям (NULL-safe), иначе выдачи размножатся при одинаковом Title
INSERT INTO checkout_facts (title_id, CheckoutYear, CheckoutMonth, MaterialType, Checkouts)
SELECT t.title_id, r.CheckoutYear, r.CheckoutMonth, r.MaterialType, r.Checkouts
FROM raw_checkouts r
JOIN titles t ON t.Title IS NOT DISTINCT FROM r.Title
             AND t.ISBN IS NOT DISTINCT FROM r.ISBN
             AND t.Creator IS NOT DISTINCT FROM r.Creator
             AND t.Publisher IS NOT DISTINCT FROM r.Publisher
             AND t.PublicationYear IS NOT DISTINCT FROM r.PublicationYear;

INSERT INTO subjects (subject_name)
SELECT DISTINCT trim(regexp_split_to_table(subjects, ','))
FROM raw_checkouts WHERE subjects IS NOT NULL
ON CONFLICT (subject_name) DO NOTHING;

INSERT INTO title_subjects (title_id, subject_id)
SELECT DISTINCT t.title_id, s.subject_id
FROM raw_checkouts r
JOIN titles t ON t.Title IS NOT DISTINCT FROM r.Title
             AND t.ISBN IS NOT DISTINCT FROM r.ISBN
             AND t.Creator IS NOT DISTINCT FROM r.Creator
             AND t.Publisher IS NOT DISTINCT FROM r.Publisher
             AND t.PublicationYear IS NOT DISTINCT FROM r.PublicationYear
CROSS JOIN LATERAL regexp_split_to_table(r.subjects, ',') AS subj(subject_name)
JOIN subjects s ON s.subject_name = trim(subj.subject_name)
WHERE r.subjects IS NOT NULL;
