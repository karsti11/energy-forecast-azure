#!/usr/bin/env bash
# Load the history into the metering database: one collector run per year.
# Usage: ./backfill.sh [first_year] [last_year]     (default: 2015 to this year)
# Safe to run again: the collector upserts, so years already loaded come back as "unchanged".
set -uo pipefail                   # no -e: one failed year should not stop the others
cd "$(dirname "$0")"
first=${1:-2015}
last=${2:-$(date +%Y)}
pause=30                           # seconds between requests; Energy-Charts answers 429 when asked too fast

docker compose build -q collector
failed=()
for year in $(seq "$first" "$last"); do
  ok=no
  for attempt in 1 2 3; do         # up to 3 tries per year, waiting longer after each failure
    echo "== $year, attempt $attempt"
    if docker compose run --rm -T collector --start "$year-01-01" --end "$year-12-31"; then
      ok=yes; break
    fi
    sleep $((pause * attempt * 2))
  done
  [ "$ok" = yes ] || failed+=("$year")
  sleep "$pause"
done

if [ ${#failed[@]} -eq 0 ]; then
  echo "backfill done: $first to $last"
else
  echo "backfill finished with failed years: ${failed[*]}"; exit 1
fi
