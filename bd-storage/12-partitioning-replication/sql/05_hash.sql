DROP TABLE IF EXISTS checkouts_hash CASCADE;

CREATE TABLE checkouts_hash (LIKE big_checkouts INCLUDING DEFAULTS)
PARTITION BY HASH (id);

CREATE TABLE checkouts_hash_0 PARTITION OF checkouts_hash FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE checkouts_hash_1 PARTITION OF checkouts_hash FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE checkouts_hash_2 PARTITION OF checkouts_hash FOR VALUES WITH (MODULUS 3, REMAINDER 2);

ALTER TABLE checkouts_hash ADD PRIMARY KEY (id);

INSERT INTO checkouts_hash SELECT * FROM big_checkouts;
VACUUM ANALYZE checkouts_hash;

SELECT tableoid::regclass AS partition,
       count(*) AS rows,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS percent
FROM checkouts_hash GROUP BY 1 ORDER BY 1;

\echo '=== lookup by id touches one partition'
EXPLAIN SELECT * FROM checkouts_hash WHERE id = 12345;

\echo '=== lookup without id touches all partitions'
EXPLAIN SELECT count(*) FROM checkouts_hash WHERE materialtype = 'SOUNDDISC';
