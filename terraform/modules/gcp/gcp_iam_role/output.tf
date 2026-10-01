output "role_id" {
  description = "The ID of the custom IAM role"
  value       = google_project_iam_custom_role.iam_custom_role.id
}

output "role_name" {
  description = "The full name of the custom IAM role"
  value       = google_project_iam_custom_role.iam_custom_role.name
}
