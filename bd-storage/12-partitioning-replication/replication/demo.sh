#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

P="docker exec -i repl-primary psql -U postgres -d lib -At"
R="docker exec -i repl-replica psql -U postgres -d lib -At"

step() { printf '\n### %s\n' "$1"; }

docker compose down -v >/dev/null 2>&1
docker compose up -d --wait >/dev/null 2>&1

step "0. schema on both servers (DDL is not replicated, so it is created by hand twice)"
SCHEMA="CREATE TABLE books (id INT PRIMARY KEY, title TEXT NOT NULL);"
echo "$SCHEMA" | $P
echo "$SCHEMA" | $R

step "1. primary: 100 rows, publication; replica: subscription"
$P -c "INSERT INTO books SELECT g, 'book ' || g FROM generate_series(1, 100) g"
$P -c "CREATE PUBLICATION pub_books FOR TABLE books"
$R -c "CREATE SUBSCRIPTION sub_books CONNECTION 'host=repl-primary dbname=lib user=postgres password=postgres' PUBLICATION pub_books"
sleep 4
echo "rows on primary: $($P -c 'SELECT count(*) FROM books')"
echo "rows on replica: $($R -c 'SELECT count(*) FROM books')"

step "2. new INSERT / UPDATE / DELETE on primary reach the replica"
$P -c "INSERT INTO books VALUES (101, 'new book')"
$P -c "UPDATE books SET title = 'updated' WHERE id = 1"
$P -c "DELETE FROM books WHERE id = 2"
sleep 2
echo "primary: $($P -c 'SELECT count(*) FROM books') rows, id=1 -> $($P -c 'SELECT title FROM books WHERE id=1')"
echo "replica: $($R -c 'SELECT count(*) FROM books') rows, id=1 -> $($R -c 'SELECT title FROM books WHERE id=1')"

step "3. DDL is not replicated: ALTER TABLE on primary"
$P -c "ALTER TABLE books ADD COLUMN author TEXT"
$P -c "INSERT INTO books VALUES (102, 'with author', 'Someone')"
sleep 5
echo "replica columns: $($R -c "SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name='books'")"
echo "replica has id=102: $($R -c 'SELECT count(*) FROM books WHERE id=102') (0 = replication is stuck)"
echo "replica log:"
docker logs repl-replica 2>&1 | grep -E "ERROR|does not exist" | tail -2
echo "fix: add the column on the replica by hand"
$R -c "ALTER TABLE books ADD COLUMN author TEXT"
sleep 6
echo "replica has id=102 after fix: $($R -c 'SELECT count(*) FROM books WHERE id=102')"

step "4. replica is writable (logical replication does not make it read-only)"
$R -c "INSERT INTO books (id, title) VALUES (500, 'written on replica')"
echo "replica has id=500: $($R -c 'SELECT count(*) FROM books WHERE id=500')"
echo "primary has id=500: $($P -c 'SELECT count(*) FROM books WHERE id=500') (changes do not flow back)"

step "5. primary stops"
docker stop repl-primary >/dev/null
echo "replica still serves reads: $($R -c 'SELECT count(*) FROM books') rows"
$R -c "INSERT INTO books (id, title) VALUES (501, 'written while primary is down')"
echo "replica accepts writes while primary is down: $($R -c 'SELECT count(*) FROM books WHERE id=501') row"
sleep 3
echo "replica log:"
docker logs repl-replica 2>&1 | grep -iE "could not connect|terminating|connection" | tail -2

step "6. primary comes back, replica catches up"
docker start repl-primary >/dev/null
for i in 1 2 3 4 5 6 7 8 9 10; do
  docker exec repl-primary pg_isready -U postgres -d lib >/dev/null 2>&1 && break
  sleep 2
done
$P -c "INSERT INTO books (id, title, author) VALUES (103, 'after restart', 'Someone')"
sleep 8
echo "replica has id=103: $($R -c 'SELECT count(*) FROM books WHERE id=103')"

step "7. conflict: same primary key written on both sides"
$R -c "INSERT INTO books (id, title) VALUES (600, 'replica first')"
$P -c "INSERT INTO books (id, title) VALUES (600, 'primary second')"
sleep 5
docker logs repl-replica 2>&1 | grep -E "duplicate key" | tail -1
