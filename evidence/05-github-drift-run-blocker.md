# GitHub-hosted drift workflow: queued-run blocker

**Observation date:** 2026-11-19 UTC  
**Repository:** `jtflack-grc/cgegcp`  
**Default branch:** `cge-gcp-capstone`  
**Workflow:** `.github/workflows/drift.yml` (`drift - nightly Terraform monitoring`)

## GitHub Actions execution attempts

Two independently manually dispatched runs were accepted by GitHub but did not create any jobs:

| Run | Event | Status at inspection | Jobs created |
|---|---|---|---|
| [44463207366](https://github.com/jtflack-grc/cgegcp/actions/runs/44463207366) | `workflow_dispatch` | `queued` | 0 |
| [44464289195](https://github.com/jtflack-grc/cgegcp/actions/runs/44464289195) | `workflow_dispatch` | `queued` | 0 |

The operator also reported GitHub's **"Failed to cancel workflow"** message. The GitHub Actions API confirmed the run status and zero-job count at the time of inspection. Neither Terraform nor the GCP federation step began in these attempts.

Other workflows in the same repository did execute: `guide-ci` passed on the capstone branch, and the `gate` workflow rejected an intentional policy violation in a closed test PR (see `evidence/03-policy-gate-denied.md`). This narrows—but does not conclusively identify—the failure to GitHub's processing of the drift workflow dispatch.

GitHub's official documentation recognizes queued workflow runs with zero created jobs and failed cancellation as a possible abnormal run state: https://docs.github.com/en/actions/how-tos/troubleshoot-workflows

## Independent Terraform results

While the hosted workflow was blocked, the operator independently ran the same read-only `terraform plan -detailed-exitcode` check from Google Cloud Shell for all **deployed** stages. All six returned exit code 0: **NO DRIFT**. See `evidence/04-manual-drift-check.md` for the exact command and outputs.

## Important limitation

The independent check **does not prove that the GitHub nightly scheduler executed successfully**. The drift workflow is defined with a nightly cron and documented; successful GitHub-hosted execution remains outstanding. These stuck runs should not be represented as a passing GitHub drift job. Do not infer that Google Cloud infrastructure is broken from a run that never created a job.
