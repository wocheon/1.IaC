resource "google_project_iam_member" "iam_role_binding" {
  project = var.project
  role    = var.role
  #member  = "serviceAccount:${var.service_account_email}"
  member = "serviceAccount:${replace(var.service_account_email, "serviceAccount:", "")}"
}
