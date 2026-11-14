\echo '=== insert year 2200 without default partition'
INSERT INTO checkouts_part (id, materialtype, checkoutyear, checkoutmonth, checkouts, title)
VALUES (900000001, 'SOUNDDISC', 2200, 1, 1, 'out of range');

\echo '=== with DEFAULT partition'
CREATE TABLE checkouts_default PARTITION OF checkouts_part DEFAULT;

INSERT INTO checkouts_part (id, materialtype, checkoutyear, checkoutmonth, checkouts, title)
VALUES (900000001, 'SOUNDDISC', 2200, 1, 1, 'out of range');

SELECT tableoid::regclass AS partition, id, checkoutyear FROM checkouts_part WHERE checkoutyear = 2200;

DELETE FROM checkouts_part WHERE id = 900000001;
