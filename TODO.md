# TODO

## Now
- Get the ENTSO-E API token (requested), store it as `ENTSOE_TOKEN`, never in the repo.
- Phase 1: schedule the collector every 15 minutes (systemd timer), then the exporter (Parquet, watermark).

## Notes for phase 2
- Silver must compare actual vs expected hours per local day (23, 24 or 25) and mark incomplete days. Example: 2022-08-31 misses 21:00 UTC, so its total is about 2 GWh too low.
- The source revises recent values (11 corrections within 2 hours on 2026-11-08); downstream must take the latest version per key.
- Data quality checks found in the first analysis (2026-11-08):
  - Empty values, not only missing timestamps: Load is empty on 2016-07-19 20:00.
  - 17 hours in 2021-2022 with all generation exactly 0 while load is normal (feed outage stored as zeros).
  - Single-hour spikes: net import -1,242 MW on 2020-03-23 15:00 between two hours of about +600 MW; load dips at 23:00 in early 2016 (e.g. 2016-02-29).
  - Missing coal and pumping values mostly mean "plant off" (0), not unknown.
  - Real events stay in but get flagged: regional blackout 2024-06-21 13:00.
  - Holidays: two holidays on one day (2024-05-30) must not lose one.
- Insights that shape the model: coastal (Split) temperature drives summer demand; behind-the-meter rooftop solar lowers midday load more each year; evening summer peak; holiday, bridge-day and day-type effects; honest baseline to beat is about 6.3% MAPE (2025).

## Next
- Download everything ENTSO-E has for Croatia, including the official day-ahead load forecast, and compare it with Energy-Charts.
- Move the data exploration (notebook, build script) into the repo once the paths and sources are final.
- Install local tools: uv, Azure CLI, Terraform, Databricks CLI, make (or a Windows-friendly task runner). Install to E:, not C:.
- Phase 2: pipeline package with tests.
- Write the Terraform code before creating the Azure account, so the 30 days of free credit go to running it.

## Ideas
- Second project later (separate repo): demand signal for apartment hosts, tourism nowcasting, daily flight arrivals.
- Small real-time endpoint after batch scoring (pending decision).
- GitHub Actions "full test" workflow: up -> demo -> down.
- Auto-teardown if the environment is up for more than 8 hours.
- Probabilistic forecast (P10 / P50 / P90) on top of the point forecast.

## Done
- Phase 0: repo, README, plan, decision log, proof plan.
- Switched to Croatia electricity demand forecasting and renamed the repo.
- Phase 1 design (decision 013) and Postgres running on the server: tables, checks and least-privilege logins verified.
- Collector with upsert and run log; backfill 2015 to today (1.69 million readings, 185 MB). Gaps in the source are counted, mixed resolutions refused.
- First data exploration: Energy-Charts load and generation, Open-Meteo weather, holidays (notebook and dashboard, outside the repo for now).
