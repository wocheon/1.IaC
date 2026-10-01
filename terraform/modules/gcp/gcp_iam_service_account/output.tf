output "service_account_id" {
  description = "The id of the service account"
  value       = google_service_account.iam_service_account.id
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.iam_service_account.email
}

output "service_account_name" {
  description = "The name of the service account"
  value       = google_service_account.iam_service_account.name
}
