\set exact '''Find Me (unabridged)'''
\set prefix '''The %'''

SELECT pg_size_pretty(pg_relation_size('idx_title_btree')) AS btree_size;

DROP INDEX idx_title_btree;
DROP INDEX idx_title_pattern;
CREATE INDEX idx_title_hash ON big_checkouts USING hash (title);
ANALYZE big_checkouts;

SELECT pg_size_pretty(pg_relation_size('idx_title_hash')) AS hash_size;

\echo '=== (b) title =, hash'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title = :exact;

\echo '=== (c) LIKE prefix, hash'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :prefix;
