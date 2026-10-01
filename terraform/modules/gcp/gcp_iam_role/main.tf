resource "google_project_iam_custom_role" "iam_custom_role" {
  role_id     = var.role_id
  title       = var.role_title
  description = var.role_description
  permissions = var.role_permissions
  project     = var.role_project_id
  stage       = var.role_stage
}
