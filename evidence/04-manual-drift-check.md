# Independent Terraform drift verification (read-only)

**Date:** 2026-11-19 UTC  
**Project:** `cge-gcp-lab`  
**Branch:** `cge-gcp-capstone`  
**Method:** Google Cloud Shell, Terraform `plan -detailed-exitcode -no-color` for each deployed stage. No Terraform apply or other mutations.

## Command

```bash
cd ~/cgegcp
for stage in 00-foundation 01-discovery 02-activation \\
             03-evidence-store 04-reporting 06-enforcement; do
  echo "===== $stage ====="
  terraform -chdir="stages/$stage" plan \\
    -detailed-exitcode -no-color > "/tmp/drift-$stage.log" 2>&1
  rc=$?
  case "$rc" in
    0) echo "NO DRIFT" ;;
    2) echo "CHANGES DETECTED — review /tmp/drift-$stage.log" ;;
    *) echo "PLAN ERROR — review /tmp/drift-$stage.log" ;;
  esac
done
```

## Actual Cloud Shell output (reported by project operator)

```text
===== 00-foundation =====
NO DRIFT
===== 01-discovery =====
NO DRIFT
===== 02-activation =====
NO DRIFT
===== 03-evidence-store =====
NO DRIFT
===== 04-reporting =====
NO DRIFT
===== 06-enforcement =====
NO DRIFT
```

**Result:** All six **deployed** stages have clean plans (Terraform exit code 0); the optional undeployed Stage 05 is excluded. This is an operator-run snapshot, **not proof of a successful scheduled GitHub Actions drift execution**. The `drift.yml` workflow is separately configured to run every night and to open an issue on detected drift. Its first manually dispatched Actions run was queued with zero jobs at the last check: https://github.com/jtflack-grc/cgegcp/actions/runs/44463207366. A successful GitHub-hosted run should be recorded separately once available.
