# Plan

Each phase ends with a short "how it works" note and a git tag, so the project can be walked through phase by phase.
Phases 0 to 2 need no Azure at all.
The Azure account is created only at phase 3, because the free credit expires 30 days after sign-up.

| # | Phase | What we build | What it proves |
|---|---|---|---|
| 0 | Foundations | Repo, README, plan, decision log, data exploration, local tools | Organised project, data understood |
| 1 | On-prem source | Postgres on a Linux server as the metering database; collector every 15 min; history backfill; exporter that pushes new rows | Realistic source system, incremental loads |
| 2 | Pipeline code | Ingestion and bronze / silver / gold transforms as a Python package with tests (clock-change days, gaps, duplicates), run locally | Data engineering, testing |
| 3 | Platform and permissions | Terraform: state storage, resource groups, ADLS, Key Vault, Databricks workspaces, Access Connectors, Unity Catalog catalogs / schemas / volumes / grants, service principals with GitHub OIDC, budget alerts | Infrastructure as code, least privilege |
| 4 | Data into the cloud | Exporter pushes to the landing volume; Auto Loader into bronze | Ingestion, moving data between services |
| 5 | Transformation | Lakeflow pipeline bronze -> silver -> gold with data quality checks and quarantine | Data engineering on the platform |
| 6 | Analytics | Demand drivers, error of the official forecast, dashboard on gold | Analytical thinking |
| 7 | Modelling | Baselines (same hour last week, official forecast) -> gradient boosting with weather and calendar, rolling backtests, MLflow, Unity Catalog registry, champion / challenger gate | Sound ML |
| 8 | Deployment | Daily job that writes tomorrow's 24 hourly forecasts before the day-ahead market closes | Model deployment |
| 9 | CI/CD | GitHub Actions: checks on PR, dev deploy, prod deploy on tag with approval; Terraform plan / apply | Automation |
| 10 | Monitoring | Daily accuracy once actuals arrive, data and feature drift, alerts, retraining trigger | Production ownership |
| 11 | Failure scenarios | Scripted break-and-fix demos | Handling problems |
| 12 | Show it off | 15-minute README, architecture diagram, screenshots, video, X article | Communication |

## Environments

- Two environments: `dev` and `prod`.
- Each has its own resource group, storage account and Databricks workspace.
- Unity Catalog: catalog per environment (`energy_dev`, `energy_prod`), schema per layer (`landing`, `bronze`, `silver`, `gold`, `ml`).
- The cloud part is temporary: built with `make up`, deleted with `make down`.
- The on-prem Postgres keeps running and keeps the history, like a real source system would.

## Cost (rough)

- On-prem part: runs on an existing server, no extra cost.
- Cloud: about 1 EUR per hour of compute while working.
- About 3-6 EUR for a 2-4 hour session when the environment is built and deleted each time.
