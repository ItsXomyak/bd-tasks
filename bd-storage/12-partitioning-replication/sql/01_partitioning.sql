DROP TABLE IF EXISTS checkouts_part CASCADE;

CREATE TABLE checkouts_part (LIKE big_checkouts INCLUDING DEFAULTS)
PARTITION BY RANGE (checkoutyear);

CREATE TABLE checkouts_2010_2014 PARTITION OF checkouts_part FOR VALUES FROM (2010) TO (2015);
CREATE TABLE checkouts_2015_2019 PARTITION OF checkouts_part FOR VALUES FROM (2015) TO (2020);
CREATE TABLE checkouts_2020_2024 PARTITION OF checkouts_part FOR VALUES FROM (2020) TO (2025);

ALTER TABLE checkouts_part ADD PRIMARY KEY (id, checkoutyear);

INSERT INTO checkouts_part SELECT * FROM big_checkouts;
VACUUM ANALYZE checkouts_part;

SELECT 'big_checkouts' AS tbl, count(*) FROM big_checkouts
UNION ALL
SELECT 'checkouts_part', count(*) FROM checkouts_part;

SELECT tableoid::regclass AS partition, count(*) FROM checkouts_part GROUP BY 1 ORDER BY 1;
