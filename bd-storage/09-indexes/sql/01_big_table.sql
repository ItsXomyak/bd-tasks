DROP TABLE IF EXISTS big_checkouts;

SELECT setseed(0.42);

CREATE TABLE big_checkouts AS
SELECT
    row_number() OVER ()                 AS id,
    r.usageclass,
    r.checkouttype,
    r.materialtype,
    2010 + floor(random() * 14)::int     AS checkoutyear,
    r.checkoutmonth,
    r.checkouts,
    r.title,
    r.isbn,
    r.creator,
    r.subjects,
    r.publisher,
    r.publicationyear
FROM raw_checkouts r
CROSS JOIN generate_series(1, 200) g;

ALTER TABLE big_checkouts ADD PRIMARY KEY (id);
VACUUM ANALYZE big_checkouts;

SELECT count(*) AS rows, pg_size_pretty(pg_total_relation_size('big_checkouts')) AS size FROM big_checkouts;
