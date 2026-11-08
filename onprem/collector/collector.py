"""Collector: copy Croatian load and generation readings from Energy-Charts into the metering database.

Usage:
  python collector.py                                   # yesterday and today (the default)
  python collector.py --start 2015-01-01 --end 2015-12-31

Days are Croatian calendar days, both included.
Connection settings come from the standard Postgres variables PGHOST, PGDATABASE, PGUSER, PGPASSWORD.
"""
import argparse
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

import psycopg
import requests

SOURCE = "energy-charts"
URL = "https://api.energy-charts.info/public_power"
HEADERS = {"User-Agent": "energy-forecast-azure collector (github.com/karsti11/energy-forecast-azure)"}
LOCAL = ZoneInfo("Europe/Zagreb")  # Energy-Charts cuts days at local midnight, not UTC midnight

# Series Energy-Charts calculates from the others. They are not meter readings, so we don't store them.
DERIVED = {"Residual load", "Renewable share of load", "Renewable share of generation"}

# Any fixed number. Postgres lets only one connection hold this lock, so two collectors never run at once.
LOCK_ID = 20261108


# ---------------------------------------------------------------- 1. fetch
def fetch(start: date, end: date) -> dict:
    """Ask Energy-Charts for Croatia from the start of `start` to the end of `end`."""
    params = {"country": "hr", "start": start.isoformat(), "end": end.isoformat()}
    r = requests.get(URL, params=params, headers=HEADERS, timeout=120)
    r.raise_for_status()  # an HTTP error (429 too many requests, 500 server error) becomes an exception
    return r.json()


# ---------------------------------------------------------------- 2. reshape: wide -> long
def to_rows(answer: dict) -> list[tuple[str, datetime, int, float]]:
    """One row per (series name, ts_utc, interval_min, value_mw). Empty values are skipped."""
    ts = answer["unix_seconds"]
    steps = {b - a for a, b in zip(ts, ts[1:])}  # gaps between consecutive timestamps, in seconds
    if len(steps) != 1:  # all gaps must be equal: 3600 (hourly) or 900 (15 min)
        raise ValueError(f"timestamps are not evenly spaced: {sorted(steps)} seconds")
    interval_min = steps.pop() // 60
    times = [datetime.fromtimestamp(t, tz=timezone.utc) for t in ts]

    rows = []
    for series in answer["production_types"]:
        if series["name"] in DERIVED:
            continue
        for t, v in zip(times, series["data"]):
            if v is not None:  # None = no value from the source; we store nothing rather than a guess
                rows.append((series["name"], t, interval_min, float(v)))
    return rows


# ---------------------------------------------------------------- 3. store: upsert
def store(conn: psycopg.Connection, rows: list) -> dict:
    """Write rows into metering.reading. New readings are inserted, changed ones updated, equal ones left alone."""
    with conn.cursor() as cur:
        # a) every series name must exist in metering.series; then look up the id of each name
        names = sorted({name for name, *_ in rows})
        cur.executemany("INSERT INTO metering.series (name) VALUES (%s) ON CONFLICT (name) DO NOTHING",
                        [(n,) for n in names])
        ids = dict(cur.execute("SELECT name, series_id FROM metering.series").fetchall())

        # b) bulk-load the answer into a temporary table with COPY (much faster than one INSERT per row).
        #    ON COMMIT DROP: the table disappears when the transaction ends.
        cur.execute("""CREATE TEMP TABLE incoming (
                           series_id smallint, ts_utc timestamptz, interval_min smallint, value_mw double precision
                       ) ON COMMIT DROP""")
        with cur.copy("COPY incoming FROM STDIN") as copy:
            for name, t, minutes, value in rows:
                copy.write_row((ids[name], t, minutes, value))

        # c) count, before changing anything, how many readings are new and how many changed
        new, changed = cur.execute("""
            SELECT count(*) FILTER (WHERE r.series_id IS NULL),
                   count(*) FILTER (WHERE r.series_id IS NOT NULL
                                    AND (r.value_mw <> i.value_mw OR r.interval_min <> i.interval_min))
            FROM incoming i
            LEFT JOIN metering.reading r USING (series_id, ts_utc)""").fetchone()

        # d) the upsert. New key -> INSERT. Existing key -> UPDATE, but only if the value really changed,
        #    so updated_at moves only on real changes and the exporter ships only real changes.
        cur.execute("""
            INSERT INTO metering.reading AS r (series_id, ts_utc, interval_min, value_mw)
            SELECT series_id, ts_utc, interval_min, value_mw FROM incoming
            ON CONFLICT (series_id, ts_utc) DO UPDATE
               SET value_mw = EXCLUDED.value_mw, interval_min = EXCLUDED.interval_min, updated_at = now()
             WHERE r.value_mw <> EXCLUDED.value_mw OR r.interval_min <> EXCLUDED.interval_min""")

    return {"received": len(rows), "inserted": new, "updated": changed, "unchanged": len(rows) - new - changed}


# ---------------------------------------------------------------- 4. run: lock, log, commit or roll back
def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--start", type=date.fromisoformat, help="first day (default: yesterday)")
    parser.add_argument("--end", type=date.fromisoformat, help="last day (default: today)")
    args = parser.parse_args()
    end = args.end or datetime.now(LOCAL).date()
    start = args.start or end - timedelta(days=1)  # overlap with the last run on purpose: catches late data and corrections
    period_from = datetime.combine(start, time(), LOCAL)                    # local midnight at the start
    period_to = datetime.combine(end + timedelta(days=1), time(), LOCAL)    # local midnight after the last day

    with psycopg.connect() as conn:  # no arguments: psycopg reads PGHOST, PGUSER, ... from the environment
        if not conn.execute("SELECT pg_try_advisory_lock(%s)", (LOCK_ID,)).fetchone()[0]:
            print("another collector is running, exiting")
            return

        run_id = conn.execute(
            "INSERT INTO metering.collector_run (source, period_from, period_to) VALUES (%s, %s, %s) RETURNING run_id",
            (SOURCE, period_from, period_to)).fetchone()[0]
        conn.commit()  # save the 'running' row now, so a crash later still leaves a trace

        try:
            rows = to_rows(fetch(start, end))
            c = store(conn, rows)
            conn.execute("""UPDATE metering.collector_run
                            SET finished_at = now(), status = 'ok', rows_received = %s,
                                rows_inserted = %s, rows_updated = %s, rows_unchanged = %s
                            WHERE run_id = %s""",
                         (c["received"], c["inserted"], c["updated"], c["unchanged"], run_id))
            conn.commit()  # readings and the run log are saved together, or not at all
            print(f"run {run_id} ok, {start} to {end}: {c}")
        except Exception as e:
            conn.rollback()  # throw away half-written readings
            conn.execute("UPDATE metering.collector_run SET finished_at = now(), status = 'failed', error = %s WHERE run_id = %s",
                         (repr(e)[:2000], run_id))
            conn.commit()
            raise  # exit with an error code, so whatever started us sees the failure


if __name__ == "__main__":
    main()
