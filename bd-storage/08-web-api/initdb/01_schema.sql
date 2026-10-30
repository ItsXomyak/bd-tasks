-- Схема из занятия 2 (HPD практика 2). Выполняется один раз при первом старте контейнера.

CREATE TABLE raw_checkouts (
    UsageClass      VARCHAR(50),
    CheckoutType    VARCHAR(50),
    MaterialType    VARCHAR(50),
    CheckoutYear    INT,
    CheckoutMonth   INT,
    Checkouts       INT,
    Title           TEXT,
    ISBN            VARCHAR(50),
    Creator         TEXT,
    Subjects        TEXT,
    Publisher       TEXT,
    PublicationYear VARCHAR(50)
);

CREATE TABLE ils_dictionary (
    Code             VARCHAR(20),
    Description      VARCHAR(200),
    CodeType         VARCHAR(50),
    FormatGroup      VARCHAR(100),
    FormatSubgroup   VARCHAR(100),
    CategoryGroup    VARCHAR(100),
    CategorySubgroup VARCHAR(100),
    AgeGroup         VARCHAR(50)
);

CREATE TABLE titles (
    title_id        SERIAL PRIMARY KEY,
    Title           TEXT,
    ISBN            VARCHAR(50),
    Creator         TEXT,
    Publisher       TEXT,
    PublicationYear VARCHAR(50)
);

CREATE TABLE checkout_facts (
    fact_id       SERIAL PRIMARY KEY,
    title_id      INT REFERENCES titles(title_id),
    CheckoutYear  INT,
    CheckoutMonth INT,
    MaterialType  VARCHAR(50),
    Checkouts     INT
);

CREATE TABLE subjects (
    subject_id   SERIAL PRIMARY KEY,
    subject_name VARCHAR(200) UNIQUE
);

CREATE TABLE title_subjects (
    title_id   INT REFERENCES titles(title_id),
    subject_id INT REFERENCES subjects(subject_id),
    PRIMARY KEY (title_id, subject_id)
);
