\set sel '''Find Me%'''

\echo '=== LIKE Find Me%, no title index'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :sel;

CREATE INDEX idx_title_pattern ON big_checkouts (title text_pattern_ops);
ANALYZE big_checkouts;

\echo '=== LIKE Find Me%, text_pattern_ops'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :sel;

DROP INDEX idx_title_pattern;
