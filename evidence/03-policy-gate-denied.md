# Policy gate negative test — verified rejection

- **Date (UTC):** 2026-11-19
- **Repository:** [jtflack-grc/cgegcp](https://github.com/jtflack-grc/cgegcp)
- **Target branch:** `cge-gcp-capstone`
- **Test pull request:** [#1 — TEST ONLY: policy gate must reject Editor grant](https://github.com/jtflack-grc/cgegcp/pull/1) (closed without merge)
- **GitHub Actions run:** [gate #1](https://github.com/jtflack-grc/cgegcp/actions/runs/44462089763)
- **Test commit:** `f36fab5b4a5e7b0e9382475f568dff85e8336de9`
- **Test resource:** `google_project_iam_member.gate_negative_test_editor` (present only in the temporary PR branch)

## Result — unsafe Terraform blocked

The negative test introduced an **unapproved `roles/editor` project IAM grant** to the `grc-collector` service account. The CI pipeline planned the change but never applied it.

The seven-stage workflow completed the six other stage jobs successfully. The `00-foundation` stage reached its policy gate and failed with:

```text
FAIL - stages/00-foundation/plan.json - main - CHK-IAM-01: google_project_iam_member.gate_negative_test_editor grants basic role roles/editor. Use a predefined or custom role.
6 tests, 5 passed, 0 warnings, 1 failure, 0 exceptions
Process completed with exit code 1.
```

**Interpretation:** This is an expected failure, proving that the PR gate blocks a prohibited basic-role grant. Authentication, Terraform planning, and the other six stage policy checks succeeded. The test PR was not merged, and no cloud resources were changed.
