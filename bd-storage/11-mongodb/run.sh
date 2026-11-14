#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p output
set -a
. ../08-web-api/.env
set +a

go run ./cmd/load    | tee output/01_load.txt
go run ./cmd/crud    | tee output/02_crud.txt
go run ./cmd/agg     | tee output/03_agg.txt
go run ./cmd/indexes | tee output/04_indexes.txt
