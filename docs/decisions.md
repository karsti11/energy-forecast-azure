# Decision log

Short records of why we chose X over Y.
Newest at the bottom.

## 001 - Synthetic data instead of a public dataset

- Options: KKBox (Kaggle), IBM Telco, our own generator.
- Chosen: our own generator (first a streaming company, changed to a retail bank in decision 008).
- Why: anyone can reproduce it without downloads or accounts, we can inject bad data and drift on demand, the churn drivers are known so we can check the model finds them, and there is no licence risk in a public repo.
- Trade-off: the data is not "real"; the focus of the project is the platform and the decisions, not leaderboard accuracy.

## 002 - Terraform for the platform, Asset Bundles for workloads

- Terraform creates things that rarely change and need admin rights: storage, workspaces, catalogs, permissions, identities.
- Databricks Asset Bundles deploy things that change with every commit: pipelines, jobs, models.

## 003 - Environment = catalog, layer = schema

- `churn_dev` and `churn_prod` catalogs, each with `landing`, `bronze`, `silver`, `gold`, `ml` schemas.
- Code is identical in every environment; only the catalog name changes.
- The prod catalog is bound to the prod workspace only.

## 004 - Two environments, no staging

- Integration tests run in dev before every prod deploy.
- A staging environment would add cost and setup without changing what the project proves.

## 005 - Deploy code, not models

- The model is trained in prod, on prod data, by the same code that was tested in dev.
- Dev trains on a sample only to prove the code works.

## 006 - Simulated on-prem source

- The generator writes daily files, as an on-prem system export would.
- In a real company this would be Data Factory or a similar tool landing files; the contract is the landing folder.

## 007 - Temporary environments

- The whole environment is built on demand and deleted afterwards.
- Data is regenerated from a fixed seed and the model is retrained, so nothing is lost.
- Keeps the cost to a few euros per session.

## 008 - Retail bank deposit churn instead of streaming

- The fictional company is a retail bank; the target is deposit churn.
- Why: banking is the target industry, and deposit churn has realistic difficulties: about 1% monthly churn (heavy imbalance), and no explicit "cancel" event, so churn has to be defined from balances.
- Credit products (loans, cards, mortgages) are features, not a second target: one model keeps the scope focused.
- Churn label: balance below 30% of its level 60 days earlier, or account closed.
- Everything is built from general, public knowledge of banking; nothing comes from any real bank.
