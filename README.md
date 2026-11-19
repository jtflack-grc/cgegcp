# CGE-GCP capstone: deployed GRC evidence pipeline

**Tenancy assumption: one Google Cloud project on a personal @gmail.com account, with no Organization above it.** Nothing in this repo needs an Organization. If you work inside one, see the appendix: `docs/APPENDIX-ORGANIZATION.md`.

This is the lab and capstone repo for **Certified GRC Engineer, GCP Specialty (CGE-GCP)** from the GRC Engineering Club Training Academy. This repository implements a staged GRC engineering pipeline in your own project:

| Stage | Folder | What it does | Runs as |
|---|---|---|---|
| 0 | `stages/00-foundation` | APIs as code; six pipeline identities created with zero permissions | you |
| 1 | `stages/01-discovery` | Measures what's running. Changes nothing. Outputs a gap map | you / CI (read-only) |
| 2 | `stages/02-activation` | Enables only what's missing: Data Access logs, 365-day audit log bucket + sink | you |
| 3 | `stages/03-evidence-store` | Firestore evidence store, locked reports bucket, daily collector running six checks (five starter + one custom) over Cloud Asset Inventory | `grc-collector` |
| 4 | `stages/04-reporting` | POA&M, SAR and OSCAL 1.1.2 SSP from Firestore only | `grc-reporter` |
| 5 | `stages/05-narrative` | Optional Gemini weekly digest. Describes, never decides | `grc-narrator` |
| 6 | `stages/06-enforcement` | Fixes public buckets on a ladder: report-only → approve → auto | `grc-remediator` |

The policy gate (`policy/*.rego`) checks every pull request's plan. `drift.yml` plans nightly and opens an issue if reality and code disagree.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/diagrams/01-pipeline-architecture-dark.png">
  <img alt="CGE-GCP pipeline architecture" src="docs/diagrams/01-pipeline-architecture.png">
</picture>

What the Terraform builds, resource by resource:

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/diagrams/07-gcp-architecture-dark.png">
  <img alt="Google Cloud resources created by the pipeline" src="docs/diagrams/07-gcp-architecture.png">
</picture>

More diagrams (identities, daily loop, remediation ladder, CI gate, data model) are in [`docs/diagrams/`](docs/diagrams/README.md).

## CGE-GCP capstone workspace (jtflack-grc)

**Deployed project:** `cge-gcp-lab` (separate from MMC); account, billing, tenancy and deployed resources verified in Google Cloud Shell on 2026-11-19.

**Default and submission branch:** `cge-gcp-capstone`. The starter `main` branch remains intact, but the public repository opens on this tested capstone branch. No merge into `main` is needed.

**Live validation (2026-11-19 UTC):** Stages 00, 01, 02, 03, 04 and 06 deployed. Discovery + activation converge with `No changes`. Six detective controls yielded 15 Firestore assessments; two original high-severity findings were remediated, then a fresh collection recorded **15 passes and 0 open failures**. The locked reports bucket denied deletion (HTTP 403), the reporter identity was denied a Firestore write (HTTP 403), and the generated OSCAL SSP passed schema validation. The POA&M, SAR and SSP were generated directly from Firestore, with original and follow-up reports retained in the locked bucket. A PR policy-gate negative test rejected a basic-role grant (see [evidence/03-policy-gate-denied.md](evidence/03-policy-gate-denied.md)) and the PR was closed without merge. Independent, read-only Terraform plans of all six deployed stages reported **no drift** (see [evidence/04-manual-drift-check.md](evidence/04-manual-drift-check.md)). The nightly drift GitHub workflow is configured; a successful hosted execution is a separate outstanding operational verification. Stage 05 narrative is intentionally optional and undeployed.

### First session: shell-only bootstrap

Use **Google Cloud Shell**, then run the following commands. The script selects the confirmed project `cge-gcp-lab`, verifies billing and tenancy, creates a project-scoped $25/month alert budget if absent, and runs AJ's initial API probe. It **does not run Terraform apply or lock retention**.

```bash
git clone --branch cge-gcp-capstone https://github.com/jtflack-grc/cgegcp.git
cd cgegcp
bash scripts/prepare-gcp-shell.sh
```

Review the output before the first Terraform deployment. This project must remain separate from MMC.

### Alternative: manual setup

Run in **Google Cloud Shell** after selecting the intended personal Google account, or in a local terminal with `gcloud`, Terraform and Git available:

```bash
git clone --branch cge-gcp-capstone https://github.com/jtflack-grc/cgegcp.git
cd cgegcp

# The actual project ID, not just its console display name:
gcloud config set project cge-gcp-lab
gcloud config list
gcloud projects describe cge-gcp-lab --format='table(projectId,name,projectNumber,parent.type)'
gcloud billing projects describe cge-gcp-lab --format='value(billingEnabled)'

# Only necessary if ADC is not yet configured for this terminal:
gcloud auth application-default print-access-token >/dev/null 2>&1 || gcloud auth application-default login

./labs/00-setup/probe.sh
```

Before deployment: establish a **$25 budget** for this project with **50%, 90%, 100%** notifications. Budget alerts **do not stop spending**. Check that the project belongs to the intended personal account and is not attached to an Organization.

Once the probe is green, deploy in this order: bootstrap the versioned Terraform state bucket (`labs/03-foundation/bootstrap.sh`), apply `00-foundation`, run discovery `01-discovery`, apply `02-activation`, rerun discovery and confirm activation converges, apply `03-evidence-store`, seed the control mappings and collect, apply `04-reporting` and generate reports, then apply `06-enforcement` with `mode=report_only`. Stage `05-narrative` is optional. Initialize each stage's independent GCS backend using `labs/03-foundation/backend.hcl`. The per-stage commands are in the corresponding lab guides. Stage 3 contains an **irreversible bucket retention lock** (default one-day retention); inspect the Terraform plan and retention period before applying it.

**The first run is intentionally limited to validation and API enablement.** It does not apply Terraform, create a retention lock, or configure IAM federation. See `docs/CAPSTONE-PLAN.md` for the grading checklist and evidence to save.

## Start here

1. `docs/SETUP.md` (account, budget, logins), then the labs in order: `labs/01-sandbox` to `labs/06-loop`.
2. One repo for every lab and the capstone: fork it, and build in your fork.
3. Before you submit: `./self-check.sh`, then read `docs/RUBRIC.md`.

Every expected output in the lab guides comes from a real run on a fresh project, recorded in `docs/VALIDATION-LOG.md`. If something surprises you, look there first.

*Built by the community, for the community · www.grcengclub.com*
