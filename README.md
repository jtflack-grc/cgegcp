# cgegcp: CGE-GCP labs and capstone starter

**Tenancy assumption: one Google Cloud project on a personal @gmail.com account, with no Organization above it.** Nothing in this repo needs an Organization. If you work inside one, see the appendix: `docs/APPENDIX-ORGANIZATION.md`.

This is the lab and capstone repo for **Certified GRC Engineer, GCP Specialty (CGE-GCP)** from the GRC Engineering Club Training Academy. You build a six-stage GRC engineering pipeline in your own project:

| Stage | Folder | What it does | Runs as |
|---|---|---|---|
| 0 | `stages/00-foundation` | APIs as code; six pipeline identities created with zero permissions | you |
| 1 | `stages/01-discovery` | Measures what's running. Changes nothing. Outputs a gap map | you / CI (read-only) |
| 2 | `stages/02-activation` | Enables only what's missing: Data Access logs, 365-day audit log bucket + sink | you |
| 3 | `stages/03-evidence-store` | Firestore evidence store, locked reports bucket, daily collector running five checks over Cloud Asset Inventory | `grc-collector` |
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

**Target GCP Project ID:** `cge-gcp-lab` (separate from MMC). The project name and ID have been confirmed by the project owner; cloud access, billing and deployed resources still need to be verified from the GCP account.

**Development branch:** `cge-gcp-capstone`. Changes live here until they are tested and merged to `main` for final grading. Do not submit the upstream starter without substantial original changes.

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

Once the probe is green, follow `labs/02-toolkit/README.md` and `labs/03-foundation/README.md` to deploy incrementally. Stage 3 contains an **irreversible bucket retention lock** (default one-day retention); inspect the Terraform plan and retention period before applying it.

**The first run is intentionally limited to validation and API enablement.** It does not apply Terraform, create a retention lock, or configure IAM federation. See `docs/CAPSTONE-PLAN.md` for the grading checklist and evidence to save.

## Start here

1. `docs/SETUP.md` (account, budget, logins), then the labs in order: `labs/01-sandbox` to `labs/06-loop`.
2. One repo for every lab and the capstone: fork it, and build in your fork.
3. Before you submit: `./self-check.sh`, then read `docs/RUBRIC.md`.

Every expected output in the lab guides comes from a real run on a fresh project, recorded in `docs/VALIDATION-LOG.md`. If something surprises you, look there first.

*Built by the community, for the community · www.grcengclub.com*
