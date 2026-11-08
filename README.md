# churn-end-to-end-azure

End-to-end customer churn project on Azure and Databricks.
From permissions and data ingestion to transformation, analytics, models, deployment and monitoring.

> Work in progress. Built step by step, one phase at a time. See [docs/plan.md](docs/plan.md).

## The business problem

A fictional retail bank loses deposits every month when customers move their money elsewhere.
Only about 1% of customers churn per month, so the problem is heavily imbalanced.
We predict who is likely to move their deposits out, then decide who gets a retention offer (a better rate or a fee waiver) within a fixed budget.
Success is measured in retained deposits net of the offer cost, compared with random targeting and "top-N most likely to churn".

## What is inside (planned)

- Synthetic data generator that acts as the company's source system, with failures that can be injected on demand.
- Azure platform built with Terraform: storage, Key Vault, Databricks workspaces, Unity Catalog, permissions.
- Ingestion into the cloud and a bronze / silver / gold pipeline with data quality checks.
- Analysis of churn drivers and revenue at risk.
- Churn model with MLflow, a champion / challenger promotion gate, and batch scoring.
- Retention offer optimization under a budget.
- CI/CD with GitHub Actions, monitoring for drift, and scripted failure scenarios with their fixes.

## Run it yourself

Coming as the phases are built.
The goal is three commands: `make up`, `make demo`, `make down`, so the environment only exists (and costs money) while you use it.

## Docs

- [Plan](docs/plan.md)
- [Decision log](docs/decisions.md)
- [Proof plan](docs/proof-plan.md)
