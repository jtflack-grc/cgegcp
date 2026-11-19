#!/usr/bin/env bash
# shellcheck disable=SC2015  # ok() always succeeds, so "a && ok || bad" is a safe if/else here
# Lab 1 probe: is this machine and project ready for the course?
# Checks the five things that broke validation runs, and enables the APIs Lab 2 needs.
# Usage: labs/00-setup/probe.sh
set -uo pipefail

ok()  { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; FAILED=1; }
FAILED=0

P=$(gcloud config get-value project 2>/dev/null)
ACCT=$(gcloud config get-value account 2>/dev/null)
echo "Project: ${P:-<none>}   Account: ${ACCT:-<none>}"
[ -n "$P" ] || { bad "no project pinned: gcloud config set project <YOUR_PROJECT_ID>"; exit 1; }
export CLOUDSDK_BILLING_QUOTA_PROJECT="$P"

# New projects do not necessarily have Resource Manager enabled. Enable APIs
# before calling projects describe, and suppress interactive auto-enable prompts.
echo "Enabling prerequisite APIs (first run may take a moment)..."
if ! gcloud services enable cloudresourcemanager.googleapis.com cloudasset.googleapis.com \
  logging.googleapis.com storage.googleapis.com cloudbilling.googleapis.com \
  --project="$P" --quiet; then
  bad "could not enable prerequisite APIs (check project owner and billing)"
  exit 1
fi

# Use the same simple JSON project lookup as the manual diagnostic.
# A formatted nested value lookup can intermittently hang on some Cloud Shell sessions.
PARENT_JSON=$(timeout 60s gcloud --quiet projects describe "$P" --format='json(parent)') || {
  bad "project parent lookup failed or timed out; verify with: gcloud projects describe $P --format=json"
  exit 1
}
parent=$(printf '%s' "$PARENT_JSON" | python3 -c 'import json,sys; p=json.load(sys.stdin).get("parent") or {}; print(p.get("type", ""))')
[ -z "$parent" ] && ok "no Organization above the project (course tenancy)" \
  || echo "  ! project sits under an $parent: fine, but read 'If you have an Organization' in docs/SETUP.md"

# Enable APIs first: with the quota project pinned, even the billing check needs
# the Cloud Billing API on (validation: SERVICE_DISABLED otherwise).
echo "Checking required APIs (Stage 0 enables the rest later)..."
for api in cloudasset logging storage cloudresourcemanager cloudbilling; do
  gcloud services list --enabled --project="$P" --filter="config.name=$api.googleapis.com" \
    --format='value(config.name)' | grep -q . && ok "$api API enabled" \
    || bad "$api API still enabling: wait two minutes and run this probe again"
done

[ "$(gcloud billing projects describe "$P" --format='value(billingEnabled)' 2>/dev/null)" = "True" ] \
  && ok "billing linked" || bad "billing not linked: Billing > Account management > link this project"

gcloud auth application-default print-access-token >/dev/null 2>&1 \
  && ok "Application Default Credentials present (Terraform will find them)" \
  || bad "no ADC: run gcloud auth application-default login"


if gcloud asset search-all-resources --scope="projects/$P" --page-size=1 --format='value(name)' >/dev/null 2>&1; then
  ok "Cloud Asset Inventory answers queries"
else
  bad "Asset Inventory not ready yet: new projects can take a few minutes after enabling the API"
fi

echo
[ "$FAILED" = 0 ] && echo "Ready for Lab 2." || echo "Fix the ✗ lines, then run this again."
exit "$FAILED"
