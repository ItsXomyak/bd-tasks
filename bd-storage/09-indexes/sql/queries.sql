\set mt '''SOUNDDISC'''
\set exact '''Find Me (unabridged)'''
\set prefix '''The %'''
\set word '''%love%'''

\echo '=== (a) year + materialtype'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE checkoutyear = 2019 AND materialtype = :mt;

\echo '=== (a2) only materialtype'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE materialtype = :mt;

\echo '=== (b) title ='
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title = :exact;

\echo '=== (c) title LIKE prefix'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title LIKE :prefix;

\echo '=== (d) title ILIKE %word%'
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(checkouts) FROM big_checkouts WHERE title ILIKE :word;
