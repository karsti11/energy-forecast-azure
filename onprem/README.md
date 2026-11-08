# On-prem source

A Postgres database on a Linux server plays the utility's metering database.
See decisions 011 and 013 in [docs/decisions.md](../docs/decisions.md) for why it looks like this.

| File | What it does |
|---|---|
| `docker-compose.yml` | Runs Postgres 16, reachable only from the server itself (127.0.0.1:5450). |
| `.env.example` | The passwords it needs. Copy to `.env`; `.env` is never committed. |
| `sql/001_schema.sql` | Tables: `series`, `reading`, `collector_run`, `export_run`. |
| `sql/002_roles.sql` | Logins `collector` (writes readings) and `exporter` (only reads). |
| `migrate.sh` | Applies all SQL files in order. Safe to run again. |

## Set up on the server

```bash
git clone https://github.com/karsti11/energy-forecast-azure.git
cd energy-forecast-azure/onprem
cp .env.example .env && chmod 600 .env    # then fill in three passwords: openssl rand -base64 24
docker compose up -d                      # start Postgres
./migrate.sh                              # create tables and logins
```

## Look inside

```bash
docker compose exec postgres psql -U admin -d metering
\dt metering.*            -- list tables
\d metering.reading       -- columns, key and checks of one table
```
