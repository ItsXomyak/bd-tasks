#!/bin/bash
set -u
PSQL="docker exec -i seattle-db psql -h 127.0.0.1 -d seattle_library -X -q"
run() {
  role=$1; label=$2; sql=$3
  out=$($PSQL -U "$role" -c "$sql" 2>&1 | head -1)
  printf '%-11s | %-14s | %s\n' "$role" "$label" "$out"
}
for role in app_reader app_writer; do
  run $role "SELECT" "SELECT count(*) FROM titles"
  run $role "INSERT titles" "INSERT INTO titles(title) VALUES ('perm check')"
  run $role "INSERT facts" "INSERT INTO checkout_facts(title_id,checkoutyear,checkoutmonth,checkouts) VALUES (NULL,2021,7,1)"
  run $role "UPDATE facts" "UPDATE checkout_facts SET checkouts = checkouts WHERE fact_id = -1"
  run $role "DELETE" "DELETE FROM checkout_facts WHERE fact_id = -1"
  run $role "DROP TABLE" "DROP TABLE subjects"
  run $role "CREATE TABLE" "CREATE TABLE hack(id int)"
done
$PSQL -U postgres -c "DELETE FROM titles WHERE title='perm check'; DELETE FROM checkout_facts WHERE title_id IS NULL AND checkoutyear=2021 AND checkoutmonth=7 AND checkouts=1 AND materialtype IS NULL" >/dev/null
