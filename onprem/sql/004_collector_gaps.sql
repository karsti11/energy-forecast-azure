-- 004_collector_gaps.sql - record how many timestamps the source skipped in a run.
-- Example: the 2022 data has no value for 2022-08-31 21:00 UTC; that run logs 1 missing timestamp.
-- Safe to run again.
ALTER TABLE metering.collector_run ADD COLUMN IF NOT EXISTS timestamps_missing integer;
