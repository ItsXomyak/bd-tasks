#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

set -a
. ../08-web-api/.env
set +a

docker compose -f ../08-web-api/docker-compose.yml exec -T db psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS seattle_cloud_sim" -c "CREATE DATABASE seattle_cloud_sim"

export LOCAL_DSN="$DATABASE_URL"
export CLOUD_DSN="${DATABASE_URL/seattle_library/seattle_cloud_sim}"

go run ./cmd/migrate
go run ./cmd/migrate && echo "second run must have failed" || echo "second run without -recreate refused, as expected"
go run ./cmd/migrate -recreate > /dev/null && echo "recreate ok"
go run ./cmd/bench
