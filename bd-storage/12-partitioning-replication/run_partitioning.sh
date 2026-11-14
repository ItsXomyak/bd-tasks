#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p output
PSQL="docker compose -f ../08-web-api/docker-compose.yml exec -T db psql -U postgres -d seattle_library"

$PSQL -v ON_ERROR_STOP=1 < sql/01_partitioning.sql | tee output/01_partitioning.txt
$PSQL -v ON_ERROR_STOP=1 < sql/02_compare.sql      | tee output/02_compare.txt
$PSQL -v ON_ERROR_STOP=1 < sql/03_detach_attach.sql | tee output/03_detach_attach.txt
$PSQL < sql/04_out_of_range.sql 2>&1               | tee output/04_out_of_range.txt
$PSQL -v ON_ERROR_STOP=1 < sql/05_hash.sql         | tee output/05_hash.txt
