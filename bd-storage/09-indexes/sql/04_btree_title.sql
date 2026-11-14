\set exact '''Find Me (unabridged)'''
\set prefix '''The %'''

CREATE INDEX idx_title_btree ON big_checkouts (title);
ANALYZE big_checkouts;

\echo '=== (b) title =, btree'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title = :exact;

\echo '=== (c) LIKE prefix, plain btree (en_US collation)'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :prefix;

CREATE INDEX idx_title_pattern ON big_checkouts (title text_pattern_ops);
ANALYZE big_checkouts;

\echo '=== (c) LIKE prefix, text_pattern_ops'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :prefix;
