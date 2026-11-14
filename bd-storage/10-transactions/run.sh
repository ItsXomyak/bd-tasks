#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p output
docker compose -f ../08-web-api/docker-compose.yml exec -T db psql -U postgres -d seattle_library -v ON_ERROR_STOP=1 < sql/00_setup_w10.sql

set -a
. ../08-web-api/.env
set +a

go run ./cmd/atomicity    | tee output/01_atomicity.txt
go run ./cmd/isolation    | tee output/02_isolation.txt
go run ./cmd/lostupdate   | tee output/03_lostupdate.txt
go run ./cmd/serializable | tee output/04_serializable.txt
go run ./cmd/deadlock     | tee output/05_deadlock.txt
go run ./cmd/mvcc         | tee output/06_mvcc.txt

docker compose -f ../08-web-api/docker-compose.yml logs db 2>&1 | grep -A6 "deadlock detected" | tail -8 | tee output/05_deadlock_server_log.txt
