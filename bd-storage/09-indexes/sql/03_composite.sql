\set mt '''SOUNDDISC'''

CREATE INDEX idx_year_material ON big_checkouts (checkoutyear, materialtype);
ANALYZE big_checkouts;

\echo '=== (a) year + materialtype, composite index'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE checkoutyear = 2019 AND materialtype = :mt;

\echo '=== (a2) only materialtype, composite index (year first)'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE materialtype = :mt;

\echo '=== (a2) only materialtype, reversed index (materialtype, checkoutyear)'
CREATE INDEX idx_material_year ON big_checkouts (materialtype, checkoutyear);
ANALYZE big_checkouts;
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE materialtype = :mt;
DROP INDEX idx_material_year;
