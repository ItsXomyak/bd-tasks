#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PSQL="docker compose -f ../08-web-api/docker-compose.yml exec -T db psql -U postgres -d seattle_library -v ON_ERROR_STOP=1"

$PSQL < sql/01_big_table.sql
$PSQL < sql/queries.sql        > plans/01_before.txt
$PSQL < sql/03_composite.sql   > plans/02_composite.txt
$PSQL < sql/04_btree_title.sql > plans/03_btree_title.txt
$PSQL < sql/05_hash_title.sql  > plans/04_hash_title.txt
$PSQL < sql/06_gin.sql         > plans/05_gin.txt
$PSQL < sql/07_bench_tables.sql

set -a
. ../08-web-api/.env
set +a
go run ./cmd/insertbench | tee plans/06_insert_cost.txt
