package schema

const DDL = `
CREATE TABLE titles (
    title_id        SERIAL PRIMARY KEY,
    title           TEXT,
    isbn            VARCHAR(50),
    creator         TEXT,
    publisher       TEXT,
    publicationyear VARCHAR(50)
);

CREATE TABLE checkout_facts (
    fact_id       SERIAL PRIMARY KEY,
    title_id      INT REFERENCES titles(title_id),
    checkoutyear  INT,
    checkoutmonth INT,
    materialtype  VARCHAR(50),
    checkouts     INT
);

CREATE TABLE subjects (
    subject_id   SERIAL PRIMARY KEY,
    subject_name VARCHAR(200) UNIQUE
);

CREATE TABLE title_subjects (
    title_id   INT REFERENCES titles(title_id),
    subject_id INT REFERENCES subjects(subject_id),
    PRIMARY KEY (title_id, subject_id)
);`

type Table struct {
	Name    string
	Columns string
	Serial  string
}

var Tables = []Table{
	{Name: "titles", Columns: "title_id, title, isbn, creator, publisher, publicationyear", Serial: "title_id"},
	{Name: "subjects", Columns: "subject_id, subject_name", Serial: "subject_id"},
	{Name: "checkout_facts", Columns: "fact_id, title_id, checkoutyear, checkoutmonth, materialtype, checkouts", Serial: "fact_id"},
	{Name: "title_subjects", Columns: "title_id, subject_id"},
}

var DropOrder = []string{"title_subjects", "checkout_facts", "subjects", "titles"}
