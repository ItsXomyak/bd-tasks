#!/bin/bash
# Кладём сертификат и ключ в PGDATA (ssl_cert_file/ssl_key_file по умолчанию = server.crt/server.key)
cp /certs/server.crt /certs/server.key "$PGDATA"/
chmod 600 "$PGDATA"/server.key
# Правило из задания 4 в начало pg_hba.conf
{ echo "hostssl university app_user 10.10.10.0/24 scram-sha-256"; cat "$PGDATA"/pg_hba.conf; } > /tmp/hba && cat /tmp/hba > "$PGDATA"/pg_hba.conf
