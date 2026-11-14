\echo '=== before detach'
SELECT count(*) AS main_rows FROM checkouts_part;

ALTER TABLE checkouts_part DETACH PARTITION checkouts_2010_2014;

\echo '=== after detach'
SELECT count(*) AS main_rows FROM checkouts_part;
SELECT count(*) AS detached_rows FROM checkouts_2010_2014;

ALTER TABLE checkouts_part ATTACH PARTITION checkouts_2010_2014 FOR VALUES FROM (2010) TO (2015);

\echo '=== after attach'
SELECT count(*) AS main_rows FROM checkouts_part;
