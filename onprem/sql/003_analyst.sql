-- 003_analyst.sql - a read-only login for people (exploring, debugging).
-- Programs and people get separate logins, so a person never borrows a program's rights.
-- Safe to run again.

SELECT 'CREATE ROLE analyst LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analyst') \gexec
ALTER ROLE analyst PASSWORD :'analyst_password';

-- A read-only login can't change data even by mistake: every transaction it starts is read-only.
ALTER ROLE analyst SET default_transaction_read_only = on;

GRANT CONNECT ON DATABASE metering TO analyst;
GRANT USAGE ON SCHEMA metering TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA metering TO analyst;
-- ...and on tables created later by admin, without granting again
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA metering GRANT SELECT ON TABLES TO analyst;
