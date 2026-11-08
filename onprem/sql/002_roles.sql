-- 002_roles.sql - one login per program, each with only the rights it needs (least privilege).
-- Run through migrate.sh, which passes the passwords in as psql variables.
-- Safe to run again.

-- CREATE ROLE has no IF NOT EXISTS. The SELECT returns the statement only when the role is missing,
-- and \gexec runs whatever the SELECT returned.
SELECT 'CREATE ROLE collector LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'collector') \gexec
SELECT 'CREATE ROLE exporter LOGIN'  WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'exporter') \gexec

-- :'name' inserts the psql variable as a quoted text value.
ALTER ROLE collector PASSWORD :'collector_password';
ALTER ROLE exporter  PASSWORD :'exporter_password';

GRANT CONNECT ON DATABASE metering TO collector, exporter;
GRANT USAGE ON SCHEMA metering TO collector, exporter;

-- collector: adds series and readings, logs its own runs. It can never delete anything.
GRANT SELECT, INSERT         ON metering.series        TO collector;
GRANT SELECT, INSERT, UPDATE ON metering.reading       TO collector;
GRANT SELECT, INSERT, UPDATE ON metering.collector_run TO collector;

-- exporter: only reads the data, and logs its own runs.
GRANT SELECT                 ON metering.series, metering.reading TO exporter;
GRANT SELECT, INSERT, UPDATE ON metering.export_run               TO exporter;
