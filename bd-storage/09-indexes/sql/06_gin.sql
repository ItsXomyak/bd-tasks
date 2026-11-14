\set word '''%love%'''

CREATE INDEX idx_title_gin ON big_checkouts USING gin (to_tsvector('english', title));
ANALYZE big_checkouts;

SELECT pg_size_pretty(pg_relation_size('idx_title_gin')) AS gin_size;

\echo '=== ILIKE %love%'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM big_checkouts WHERE title ILIKE :word;

\echo '=== to_tsvector @@ to_tsquery'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM big_checkouts WHERE to_tsvector('english', title) @@ to_tsquery('english', 'love');

\echo '=== row counts'
SELECT count(*) AS ilike_rows FROM big_checkouts WHERE title ILIKE :word;
SELECT count(*) AS fts_rows FROM big_checkouts WHERE to_tsvector('english', title) @@ to_tsquery('english', 'love');

\echo '=== found by ILIKE but not by FTS'
SELECT DISTINCT title FROM big_checkouts WHERE title ILIKE :word AND NOT to_tsvector('english', title) @@ to_tsquery('english', 'love') LIMIT 8;

\echo '=== found by FTS but not by ILIKE'
SELECT DISTINCT title FROM big_checkouts WHERE NOT title ILIKE :word AND to_tsvector('english', title) @@ to_tsquery('english', 'love') LIMIT 8;
