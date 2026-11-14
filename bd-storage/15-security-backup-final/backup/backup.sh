#!/bin/bash
set -eu
cd "$(dirname "$0")"
C=seattle-db
PG="docker exec -i $C psql -U postgres -X -At"
TABLES="titles checkout_facts subjects title_subjects"
count() {
  for t in $TABLES; do echo "$t $($PG -d "$1" -c "SELECT count(*) FROM $t")"; done
}

$PG -d postgres -c "DROP DATABASE IF EXISTS seattle_victim" -c "DROP DATABASE IF EXISTS seattle_restore" >/dev/null
$PG -d postgres -c "CREATE DATABASE seattle_victim TEMPLATE seattle_library" >/dev/null

count seattle_victim > before.txt
echo "== before"; cat before.txt

docker exec $C pg_dump -U postgres -Fc -t titles -t checkout_facts -t subjects -t title_subjects -f /tmp/seattle_library.dump seattle_victim
docker cp $C:/tmp/seattle_library.dump ./seattle_library.dump
ls -l seattle_library.dump

$PG -d seattle_victim -c "DROP TABLE title_subjects, checkout_facts, subjects, titles CASCADE" >/dev/null
echo "== accident: tables dropped in seattle_victim"
$PG -d seattle_victim -c "SELECT count(*) FROM titles" 2>&1 || true

$PG -d postgres -c "CREATE DATABASE seattle_restore" >/dev/null
docker exec $C pg_restore -U postgres -d seattle_restore --exit-on-error /tmp/seattle_library.dump
echo "== restored"
count seattle_restore > after.txt
cat after.txt

if diff before.txt after.txt >/dev/null; then echo "MATCH: counts equal"; else echo "MISMATCH"; exit 1; fi
