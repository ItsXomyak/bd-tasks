DROP TABLE IF EXISTS bench_noidx, bench_idx;

CREATE TABLE bench_noidx (LIKE big_checkouts INCLUDING DEFAULTS);
CREATE TABLE bench_idx   (LIKE big_checkouts INCLUDING DEFAULTS);

CREATE INDEX bench_idx_year_material ON bench_idx (checkoutyear, materialtype);
CREATE INDEX bench_idx_title_btree   ON bench_idx (title);
CREATE INDEX bench_idx_title_gin     ON bench_idx USING gin (to_tsvector('english', title));
