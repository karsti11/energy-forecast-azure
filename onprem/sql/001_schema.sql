-- 001_schema.sql - tables of the on-prem metering database.
-- Safe to run again: every statement uses IF NOT EXISTS.

-- A schema is a namespace inside the database, like a folder for tables.
CREATE SCHEMA IF NOT EXISTS metering;

-- One row per data series, e.g. 'Load', 'Solar', 'Wind onshore'.
CREATE TABLE IF NOT EXISTS metering.series (
    series_id    smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- 1, 2, 3 ... assigned by Postgres
    name         text NOT NULL UNIQUE,                               -- exactly as the source names it
    unit         text NOT NULL DEFAULT 'MW',
    description  text,
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- One row per series and timestamp: the meter readings. Long format.
CREATE TABLE IF NOT EXISTS metering.reading (
    series_id     smallint NOT NULL REFERENCES metering.series (series_id),  -- must exist in series
    ts_utc        timestamptz NOT NULL,          -- start of the interval
    interval_min  smallint NOT NULL,             -- length of the interval: 60 until 2024, 15 from 2025
    value_mw      double precision NOT NULL,     -- average power over the interval
    inserted_at   timestamptz NOT NULL DEFAULT now(),  -- first time we stored this reading
    updated_at    timestamptz NOT NULL DEFAULT now(),  -- last time its value changed; drives the export
    PRIMARY KEY (series_id, ts_utc),             -- one value per series and moment, never two
    CONSTRAINT interval_is_15_or_60 CHECK (interval_min IN (15, 60)),
    -- a reading starts on a whole quarter hour (900 seconds), e.g. 14:00 or 14:15, never 14:07
    CONSTRAINT ts_on_quarter_hour CHECK (extract(epoch FROM ts_utc)::bigint % 900 = 0)
);

-- The exporter asks "which rows changed after time X?"; this index answers that without reading the whole table.
CREATE INDEX IF NOT EXISTS reading_updated_at_idx ON metering.reading (updated_at);

-- One row per collector run: what it asked for and what it changed.
CREATE TABLE IF NOT EXISTS metering.collector_run (
    run_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    started_at      timestamptz NOT NULL DEFAULT now(),
    finished_at     timestamptz,
    source          text NOT NULL,               -- e.g. 'energy-charts'
    period_from     timestamptz NOT NULL,        -- period requested from the source
    period_to       timestamptz NOT NULL,
    rows_received   integer,                     -- non-empty values in the answer
    rows_inserted   integer,                     -- new readings
    rows_updated    integer,                     -- existing readings whose value changed
    rows_unchanged  integer,                     -- existing readings, same value
    status          text NOT NULL DEFAULT 'running',
    error           text,
    CONSTRAINT collector_status CHECK (status IN ('running', 'ok', 'failed'))
);

-- One row per export run. The watermark is the newest updated_at that was shipped.
-- The next export takes rows with updated_at > the last successful watermark_to.
CREATE TABLE IF NOT EXISTS metering.export_run (
    run_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    started_at      timestamptz NOT NULL DEFAULT now(),
    finished_at     timestamptz,
    watermark_from  timestamptz,                 -- exclusive; NULL on the very first export
    watermark_to    timestamptz,                 -- inclusive
    rows_exported   integer,
    file_name       text,
    status          text NOT NULL DEFAULT 'running',
    error           text,
    CONSTRAINT export_status CHECK (status IN ('running', 'ok', 'failed'))
);
