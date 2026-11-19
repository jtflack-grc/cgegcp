# INTENTIONALLY NONCOMPLIANT — NEGATIVE CI GATE TEST ONLY.
# This branch is never to be merged or applied. A passing policy gate must block it.
resource "google_project_iam_member" "gate_negative_test_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:grc-collector@${var.project_id}.iam.gserviceaccount.com"
}
