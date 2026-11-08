# energy-forecast-azure

End-to-end electricity demand forecasting for Croatia on Azure and Databricks.
From an on-prem source database and permissions to ingestion, transformation, analytics, models, deployment and monitoring.

> Work in progress. Built step by step, one phase at a time. See [docs/plan.md](docs/plan.md).

## The business problem

Every morning, the companies that run and supply the Croatian grid must say how much electricity the country will use tomorrow, hour by hour.
They buy energy on the day-ahead market based on that forecast.
Every MWh they get wrong is paid for later at imbalance prices, which are usually worse than the day-ahead price.

We build a day-ahead load forecast for Croatia and compare it with the official forecast that the transmission system operator publishes on the ENTSO-E Transparency Platform.
Success is measured as lower forecast error than the official forecast and simple baselines, turned into euros with clearly stated imbalance cost assumptions.

## Data

All real and public:

| Source | What | History |
|---|---|---|
| ENTSO-E Transparency Platform | Actual load, official day-ahead load forecast, generation by source, wind and solar forecasts | 2015 to today, 15 min |
| Energy-Charts (Fraunhofer ISE) | Load and generation by source, no account needed | Load from 2015, generation from 2019 |
| Open-Meteo (ERA5) | Hourly weather for Zagreb, Split and Osijek | 1940 to today |
| Nager.Date | Croatian public holidays | 2015 to next year |

Day-ahead prices from Energy-Charts are licensed for private use only, so they are not used in this repo.

## Architecture (planned)

- **On-prem source:** a Postgres database on a Linux server plays the utility's metering database.
  A collector writes new 15-minute readings into it, and an exporter pushes new rows to Azure storage (outbound only, no open ports).
- **Platform:** Azure with Terraform: storage, Key Vault, Databricks workspaces, Unity Catalog, permissions, budget alerts.
- **Pipeline:** Auto Loader and a bronze / silver / gold pipeline with data quality checks.
- **Analytics:** what drives demand (temperature, calendar, tourism season) and how good the official forecast is.
- **Model:** baselines, then gradient boosting with weather and calendar features, time-based backtests, MLflow, champion / challenger gate.
- **Deployment:** a daily job that publishes tomorrow's hourly forecast before the market closes.
- **Operations:** CI/CD with GitHub Actions, accuracy and drift monitoring, scripted failure scenarios with their fixes.

## Run it yourself

Coming as the phases are built.
The goal is three commands: `make up`, `make demo`, `make down`, so the cloud environment only exists (and costs money) while you use it.

## Docs

- [Plan](docs/plan.md)
- [Decision log](docs/decisions.md)
- [Proof plan](docs/proof-plan.md)
