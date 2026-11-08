#!/usr/bin/env bash
# Apply every sql/NNN_*.sql file in number order, inside the running Postgres container.
# Every SQL file is safe to run again, so this script is too.
set -euo pipefail                  # stop at the first error, on unset variables, and on errors inside pipes
cd "$(dirname "$0")"               # work from the onprem folder, wherever the script is called from
set -a; source .env; set +a        # read the passwords from .env into environment variables

for f in sql/[0-9][0-9][0-9]_*.sql; do
  echo "applying $f"
  # -T: no terminal, so we can feed the file through stdin (-f -)
  # ON_ERROR_STOP=1: psql stops and fails at the first SQL error instead of carrying on
  docker compose exec -T postgres psql -U admin -d metering -q -v ON_ERROR_STOP=1 \
    -v collector_password="$COLLECTOR_PASSWORD" -v exporter_password="$EXPORTER_PASSWORD" \
    -v analyst_password="$ANALYST_PASSWORD" \
    -f - < "$f"
done
echo "done"
