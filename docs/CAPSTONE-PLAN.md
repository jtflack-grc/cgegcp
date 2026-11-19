# CGE-GCP capstone execution plan

**Status:** planning only; no GCP infrastructure deployed.

**Target tenancy:** Dedicated personal-Gmail Google Cloud project, no Organization parent. Keep all resources separate from MMC. Confirm actual project ID before deployment; never commit secrets, credential files, personal details, or live project credentials.

**Scoring goal:** 100/100 on five equally weighted capstone dimensions. The [Academy rubric](https://cert.grcengclub.com/rubric/cge-gcp) takes precedence over the repository copy when they differ.

## Deployment order

1. Create a fresh GCP project and set a $25 budget with alerts at 50%, 90%, and 100% (alerts are not spend caps). Confirm active project and Application Default Credentials locally.
2. Run `./labs/00-setup/probe.sh` against the dedicated project.
3. Deploy Stage 0 identities/APIs, followed by read-only Stage 1 discovery. Record the initial gap map.
4. Deploy Stage 2 only for observed gaps; retain Terraform ownership of resources it created.
5. Deploy Stage 3 evidence store and daily collector promptly, so natural run history accumulates.
6. Deploy Stage 4 reports from Firestore, with evidence provenance and a locked WORM bucket.
7. Implement and test an **original sixth detective control**, with passing/failing fixtures, collector mappings, and matching `docs/CONTROLS.md`. Candidate: flag bucket configurations that fail `public_access_prevention = "enforced"`; verify its exact scope against the five starter checks before deciding.
8. Deploy Stage 6 remediator initially as `report_only`; document limited role and blast radius. Never activate automatic correction without a reviewed decision.
9. Arm gate and drift workflows against this fork using keyless federation; prove a noncompliant test PR is blocked and then close it.
10. Capture WORM failed-delete evidence, reporter denied-access evidence, scheduled collection history, and at least two reports generated only from Firestore.
11. Run `./self-check.sh`, security/secret scans, tests, Terraform format/validation and documentation cross-check before submission.

## Grading evidence matrix

| Dimension | Verification artifacts |
| --- | --- |
| Infrastructure as code | Separate state by stage; pinned providers; additive IAM; documented discovery-first activation |
| Control implementation | Dedicated zero-key identities; custom remediation role; tested original control |
| Integrity and traceability | WORM failed-delete proof; deterministic IDs and timestamps; Firestore-to-asset trace |
| Operations | Daily run history; PR gate block; active drift detection; controlled remediation |
| Documentation | Cold-start README, accurate CONTROLS.md, tenancy assumptions and blast-radius rationale |

## Submission guardrails

- Public fork containing substantial original changes, not a trivially edited starter.
- No service-account JSON keys, secrets, PII, or production data in Git history.
- Evidence screenshots/logs must be sanitized for public disclosure.
- Stage 5 is optional and should not delay core graded requirements.
- Do not lock retention on the reports bucket until the configured duration, cleanup implications, and budget are understood.
- Keep the two graded submission attempts for when the repository is demonstrably ready.
