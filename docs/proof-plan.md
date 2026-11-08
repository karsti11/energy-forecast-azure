# Proof plan

What we want to show, and the evidence for it.
Tick items off as the screenshots and results are captured.

| Claim | Evidence | Asset | Done |
|---|---|---|---|
| It saves money | Forecast error vs the official forecast and naive baselines over a rolling backtest, turned into imbalance cost with stated assumptions | Error-by-month chart, euro table in README | [ ] |
| We understand it | Time-based backtests, error by hour, season and holiday, decision log | Architecture diagram, MLflow comparison, Unity Catalog lineage | [ ] |
| Failures are handled | Scripted scenarios below | Pipeline check failures, blocked promotion, drift dashboard, job history | [ ] |
| CI/CD works | PR -> dev, tag -> prod | GitHub Actions run, green badge | [ ] |
| Anyone can reproduce it | README quickstart, three commands | Timed fresh-clone run | [ ] |

## Failure scenarios

1. Bad data arrives (negative load, spikes, duplicate timestamps) - quality checks quarantine it.
2. The source schema changes (a new generation type appears, as batteries did in 2026) - the pipeline handles or flags it.
3. Data arrives late or not at all (API outage, exporter down) - the next run backfills the gap, and loads are idempotent.
4. Clock-change days (23 and 25 hours) - handled in code and covered by tests.
5. A worse model is trained - the gate keeps the current model.
6. Demand behaviour drifts (heatwave, new rooftop solar) - monitoring alerts and retraining starts.
7. A job fails - retry and notification.
8. Rollback - prod returns to the previous model with one command.
9. Missing permission on a new table - fixed through Terraform grants, not by clicking in the UI.
