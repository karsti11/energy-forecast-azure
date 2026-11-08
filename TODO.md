# TODO

## Now
- Review the prototype bank data (sample dashboard) and agree on tables, columns and churn drivers.

## Next
- Turn the prototype into the real generator in the repo (Python package, fixed seed, `--inject bad_data / drift`, daily files).
- Analysis notebook on the generated data: churn drivers, cohorts, revenue at risk.
- Install local tools: uv, Azure CLI, Terraform, Databricks CLI, make (or a Windows-friendly task runner). Install to E:, not C:.
- Phase 1: Azure platform with Terraform.

## Ideas
- Azure Data Factory step for moving files between storage (pending decision).
- Small real-time endpoint after batch scoring (pending decision).
- GitHub Actions "full test" workflow: up -> demo -> down.
- Auto-teardown if the environment is up for more than 8 hours.

## Done
- Phase 0: repo, README, plan, decision log, proof plan.
