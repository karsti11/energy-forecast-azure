# On-prem source

A Postgres database on a Linux server plays the utility's metering database.
See decisions 011 and 013 in [docs/decisions.md](../docs/decisions.md) for why it looks like this.

| File | What it does |
|---|---|
| `docker-compose.yml` | Runs Postgres 16, reachable only from the server itself (127.0.0.1:5450), and the collector job. |
| `.env.example` | The passwords it needs. Copy to `.env`; `.env` is never committed. |
| `sql/001_schema.sql` | Tables: `series`, `reading`, `collector_run`, `export_run`. |
| `sql/002_roles.sql` | Logins for programs: `collector` (writes readings, never deletes) and `exporter` (only reads). |
| `sql/003_analyst.sql` | Login for people: `analyst` (reads everything, changes nothing). |
| `migrate.sh` | Applies all SQL files in order. Safe to run again. |
| `collector/` | The collector: Energy-Charts -> `metering.reading`. |
| `queries.sql` | Example queries. |

## Set up on the server

```bash
git clone https://github.com/karsti11/energy-forecast-azure.git
cd energy-forecast-azure/onprem
cp .env.example .env && chmod 600 .env    # then fill in the passwords: openssl rand -hex 24
docker compose up -d                      # start Postgres
./migrate.sh                              # create tables and logins
```

## Run the collector

```bash
docker compose build collector                                         # after every code change
docker compose run --rm collector                                      # yesterday and today
docker compose run --rm collector --start 2015-01-01 --end 2015-12-31  # any period, Croatian days
```

Running it twice over the same period changes nothing: the second run reports every row as `unchanged`.

## Log in and query

From your own computer (PowerShell or any terminal), log in as `analyst`, the read-only login for people.

**1. Interactive psql on the server:**

```bash
ssh -t karlo@178.104.61.7 "cd ~/energy-forecast-azure/onprem && docker compose exec postgres psql -U analyst -d metering"
```

No password is asked: inside the container, Postgres trusts local connections.
Anyone who can run Docker on the server already has full control of it, so this adds no risk.
Useful psql commands: `\dt metering.*` lists tables, `\d metering.reading` shows a table, `\q` quits.

**2. Run all example queries at once:**

```bash
ssh karlo@178.104.61.7 "cd ~/energy-forecast-azure/onprem && docker compose exec -T postgres psql -U analyst -d metering -X < queries.sql"
```

**3. A GUI (DBeaver, the VS Code PostgreSQL extension) or Python on your computer, through an SSH tunnel:**

```bash
ssh -N -L 5450:127.0.0.1:5450 karlo@178.104.61.7     # keep this window open while you work
```

Then connect to host `localhost`, port `5450`, database `metering`, user `analyst`.
The tunnel forwards your local port 5450 to the server's 127.0.0.1:5450 through SSH, so the database never has to face the internet.
The password is in the server's `.env`: `ssh karlo@178.104.61.7 "grep ANALYST ~/energy-forecast-azure/onprem/.env"`.
