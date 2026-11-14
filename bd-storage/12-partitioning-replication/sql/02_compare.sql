\echo '=== 1. big_checkouts, year = 2019 (has composite index idx_year_material)'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*), sum(checkouts) FROM big_checkouts WHERE checkoutyear = 2019;

\echo '=== 2. big_checkouts, year = 2019, index dropped inside a rolled-back transaction'
BEGIN;
DROP INDEX idx_year_material;
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*), sum(checkouts) FROM big_checkouts WHERE checkoutyear = 2019;
ROLLBACK;

\echo '=== 3. checkouts_part, year = 2019 (partition pruning)'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*), sum(checkouts) FROM checkouts_part WHERE checkoutyear = 2019;

\echo '=== 4. big_checkouts, materialtype only'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*), sum(checkouts) FROM big_checkouts WHERE materialtype = 'SOUNDDISC';

\echo '=== 5. checkouts_part, materialtype only (no partition key, no pruning)'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*), sum(checkouts) FROM checkouts_part WHERE materialtype = 'SOUNDDISC';
