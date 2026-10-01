output "bucket_name" {
  description = "The name of the bucket."
  value       = google_storage_bucket.gcs_bucket.name
}

output "bucket_stoarge_class" {
  description = "The storage_class of the bucket."
  value       = google_storage_bucket.gcs_bucket.storage_class
}

output "bucket_url" {
  description = "The URL of the bucket."
  value       = "gs://${google_storage_bucket.gcs_bucket.name}"
}

