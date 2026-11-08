-- queries.sql - handy queries for the metering database. See README.md for how to open psql.
-- Times are stored in UTC; "AT TIME ZONE 'Europe/Zagreb'" shows them in Croatian time.

-- 1. Which series exist, and how many readings each has.
SELECT s.series_id, s.name, s.unit, count(r.series_id) AS readings,
       min(r.ts_utc) AS first_utc, max(r.ts_utc) AS last_utc
FROM metering.series s
LEFT JOIN metering.reading r USING (series_id)
GROUP BY s.series_id, s.name, s.unit
ORDER BY s.series_id;

-- 2. The newest load readings, in Croatian time.
SELECT r.ts_utc AT TIME ZONE 'Europe/Zagreb' AS local_time, r.interval_min, r.value_mw
FROM metering.reading r
JOIN metering.series s USING (series_id)
WHERE s.name = 'Load'
ORDER BY r.ts_utc DESC
LIMIT 8;

-- 3. Back to wide format for the last 2 hours: one column per source, like the raw file.
SELECT r.ts_utc AT TIME ZONE 'Europe/Zagreb' AS local_time,
       max(r.value_mw) FILTER (WHERE s.name = 'Load')                             AS load_mw,
       max(r.value_mw) FILTER (WHERE s.name = 'Hydro Run-of-River')               AS hydro_river_mw,
       max(r.value_mw) FILTER (WHERE s.name = 'Wind onshore')                     AS wind_mw,
       max(r.value_mw) FILTER (WHERE s.name = 'Solar')                            AS solar_mw,
       max(r.value_mw) FILTER (WHERE s.name = 'Fossil gas')                       AS gas_mw,
       max(r.value_mw) FILTER (WHERE s.name = 'Cross border electricity trading') AS net_import_mw
FROM metering.reading r
JOIN metering.series s USING (series_id)
WHERE r.ts_utc > now() - interval '2 hours'
GROUP BY r.ts_utc
ORDER BY r.ts_utc;

-- 4. Energy used per Croatian day, GWh: MW x hours of each interval, summed, / 1000.
SELECT (r.ts_utc AT TIME ZONE 'Europe/Zagreb')::date AS local_day,
       count(*) AS readings,
       round((sum(r.value_mw * r.interval_min / 60.0) / 1000)::numeric, 2) AS load_gwh
FROM metering.reading r
JOIN metering.series s USING (series_id)
WHERE s.name = 'Load'
GROUP BY 1
ORDER BY 1 DESC
LIMIT 7;

-- 5. The collector's run log, newest first.
SELECT run_id, started_at, finished_at - started_at AS took, status,
       rows_received, rows_inserted, rows_updated, rows_unchanged, left(error, 80) AS error
FROM metering.collector_run
ORDER BY run_id DESC
LIMIT 10;
