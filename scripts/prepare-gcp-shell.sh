#!/usr/bin/env bash
# Safe first-run preparation for the dedicated CGE-GCP lab project.
# No Terraform apply, resource teardown, WORM lock, or credential creation here.
set -euo pipefail

PROJECT="cge-gcp-lab"
BUDGET_NAME="CGE-GCP Lab Guardrail"

command -v gcloud >/dev/null || { echo "gcloud is required (use Google Cloud Shell)."; exit 1; }

echo "== Confirm project =="
gcloud config set project "$PROJECT" >/dev/null
# Ensure Cloud Resource Manager API is enabled before project ancestry checks.
gcloud services enable cloudresourcemanager.googleapis.com --project="$PROJECT" --quiet >/dev/null
ACTUAL_ID="$(gcloud projects describe "$PROJECT" --format='value(projectId)')"
[ "$ACTUAL_ID" = "$PROJECT" ] || { echo "Unexpected project ID: $ACTUAL_ID"; exit 1; }
gcloud projects describe "$PROJECT" --format='table(projectId,name,projectNumber,parent.type)'
ACTIVE_ACCOUNT="$(gcloud auth list --filter='status:ACTIVE' --format='value(account)' | head -n1)"
echo "Active account: $ACTIVE_ACCOUNT"
[ -n "$ACTIVE_ACCOUNT" ] || { echo "No active gcloud identity"; exit 1; }

PARENT_JSON="$(timeout 60s gcloud --quiet projects describe "$PROJECT" --format='json(parent)')" || {
  echo "STOP: project ancestry lookup failed or timed out."
  exit 1
}
PARENT="$(printf '%s' "$PARENT_JSON" | python3 -c 'import json,sys; p=json.load(sys.stdin).get("parent") or {}; print(p.get("type", ""))')"
if [ -n "$PARENT" ]; then
  echo "STOP: project has parent type '$PARENT'; investigate tenancy before continuing."
  exit 1
fi

echo "== Confirm billing =="
BILLING_ENABLED="$(gcloud billing projects describe "$PROJECT" --format='value(billingEnabled)')"
BILLING_NAME="$(gcloud billing projects describe "$PROJECT" --format='value(billingAccountName)')"
[ "$BILLING_ENABLED" = "True" ] || { echo "STOP: project billing not enabled"; exit 1; }
[ -n "$BILLING_NAME" ] || { echo "STOP: project has no linked billing account"; exit 1; }
BILLING_ID="${BILLING_NAME#billingAccounts/}"
echo "Billing enabled (billing account linked)."

echo "== Confirm scoped budget (USD 25/month, thresholds 50%, 90%, 100%) =="
# This API operation is free, but it requires budget permissions on the billing account.
gcloud services enable billingbudgets.googleapis.com --project="$PROJECT" >/dev/null
if gcloud billing budgets list --billing-account="$BILLING_ID" \
    --format='value(displayName)' | grep -Fxq "$BUDGET_NAME"; then
  echo "Budget '$BUDGET_NAME' already exists; inspect it if settings were changed."
else
  gcloud billing budgets create \
    --billing-account="$BILLING_ID" \
    --display-name="$BUDGET_NAME" \
    --budget-amount=25USD \
    --filter-projects="projects/$PROJECT" \
    --calendar-period=month \
    --credit-types-treatment=exclude-all-credits \
    --threshold-rule=percent=0.50 \
    --threshold-rule=percent=0.90 \
    --threshold-rule=percent=1.00
fi
echo "NOTE: Budget alerts do NOT cap spending."

echo "== Run starter environment probe =="
./labs/00-setup/probe.sh

echo "== Available tooling =="
command -v terraform && terraform version | head -n2 || echo "Terraform not present yet"
command -v conftest && conftest --version || echo "conftest not present yet"
echo "READY FOR REVIEW: no Terraform resources applied."
