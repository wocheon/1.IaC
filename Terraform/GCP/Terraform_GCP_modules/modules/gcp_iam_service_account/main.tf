resource "google_service_account" "iam_service_account" {
  account_id   = var.new_service_account_id
  display_name = var.new_service_account_display_name
  description  = var.new_service_account_description
  project      = var.new_service_account_project_id
}
