output "private_key" {
  value     = google_service_account_key.this.private_key
  sensitive = true
}

output "private_key_file" {
  value     = base64decode(google_service_account_key.this.private_key)
  sensitive = true
}
