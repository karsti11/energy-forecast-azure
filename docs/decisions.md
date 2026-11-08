# Decision log

Short records of why we chose X over Y.
Newest at the bottom.
A decision that was later replaced is marked "superseded" and kept, so the history stays readable.

## 001 - Synthetic data instead of a public dataset (superseded by 010)

- Options: KKBox (Kaggle), IBM Telco, our own generator.
- Chosen: our own generator (first a streaming company, changed to a retail bank in decision 008).
- Why: anyone can reproduce it without downloads or accounts, we can inject bad data and drift on demand, the churn drivers are known so we can check the model finds them, and there is no licence risk in a public repo.
- Trade-off: the data is not "real"; the focus of the project is the platform and the decisions, not leaderboard accuracy.

## 002 - Terraform for the platform, Asset Bundles for workloads

- Terraform creates things that rarely change and need admin rights: storage, workspaces, catalogs, permissions, identities.
- Databricks Asset Bundles deploy things that change with every commit: pipelines, jobs, models.

## 003 - Environment = catalog, layer = schema

- `energy_dev` and `energy_prod` catalogs (named `churn_dev` and `churn_prod` before decision 009), each with `landing`, `bronze`, `silver`, `gold`, `ml` schemas.
- Code is identical in every environment; only the catalog name changes.
- The prod catalog is bound to the prod workspace only.

## 004 - Two environments, no staging

- Integration tests run in dev before every prod deploy.
- A staging environment would add cost and setup without changing what the project proves.

## 005 - Deploy code, not models

- The model is trained in prod, on prod data, by the same code that was tested in dev.
- Dev trains on a sample only to prove the code works.

## 006 - Simulated on-prem source (superseded by 011)

- The generator writes daily files, as an on-prem system export would.
- In a real company this would be Data Factory or a similar tool landing files; the contract is the landing folder.

## 007 - Temporary environments

- The cloud environment is built on demand and deleted afterwards.
- Data is reloaded from the on-prem source (decision 011) and the model is retrained, so nothing is lost.
- Keeps the cost to a few euros per session.

## 008 - Retail bank deposit churn instead of streaming (superseded by 009)

- The fictional company is a retail bank; the target is deposit churn.
- Why: deposit churn has realistic difficulties: about 1% monthly churn (heavy imbalance), and no explicit "cancel" event, so churn has to be defined from balances.
- Credit products (loans, cards, mortgages) are features, not a second target: one model keeps the scope focused.
- Churn label: balance below 30% of its level 60 days earlier, or account closed.
- Everything is built from general, public knowledge of banking; nothing comes from any real bank.

## 009 - Croatia electricity demand forecast instead of bank churn

- The project forecasts Croatian electricity load for the next day, hour by hour.
- Why: electricity demand has real public data at 15-minute detail, a clear business value (day-ahead buying and imbalance costs) and an official forecast to compare against.
  Synthetic bank data could never show how the model does on real-world data.
- Also considered: Croatian tourism (most public data is monthly, too coarse for daily decisions) and stocks or crypto (no clear business value to prove).
- The repo was renamed from `churn-end-to-end-azure` to `energy-forecast-azure`.

## 010 - Real public data instead of synthetic

- Sources: ENTSO-E Transparency Platform, Energy-Charts, Open-Meteo, Nager.Date.
- Why: real data has real problems (gaps, clock-change days, new generation types appearing), which makes the failure scenarios honest.
- Licences: ENTSO-E, Energy-Charts load and generation, and Open-Meteo allow reuse with attribution.
  Energy-Charts day-ahead prices are for private use only, so they are not used in this repo.
- Bad data and drift can still be injected on purpose for the failure demos.

## 011 - On-prem source: Postgres on a Linux server, pushed outbound

- A Postgres database on a Linux server plays the utility's metering database.
  A collector adds new 15-minute readings, and an exporter pushes new rows to the cloud landing area.
- Why push and not pull: the database never has to be reachable from the internet, and no ports are opened.
  It also works when the cloud environment does not exist yet.
- Why not Data Factory with a self-hosted integration runtime: that runtime runs only on Windows, and the server runs Linux.
- Loads are incremental by timestamp and idempotent, so a rerun or a backfill never creates duplicates.

## 012 - Benchmark: the official day-ahead load forecast

- The transmission system operator publishes its own day-ahead load forecast on ENTSO-E.
- Our model is judged against it and against simple baselines (same hour last week, same hour yesterday).
- Why: beating a naive baseline is easy; beating the forecast the market actually uses is the claim worth making.
