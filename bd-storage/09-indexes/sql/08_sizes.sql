SELECT indexname, pg_size_pretty(pg_relation_size(indexname::regclass)) AS size
FROM pg_indexes
WHERE tablename IN ('big_checkouts', 'bench_idx')
ORDER BY indexname;
