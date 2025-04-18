output "id" {
  value = google_compute_image.gce_image.id
}

output "disk_size_gb" {
  value = google_compute_image.gce_image.disk_size_gb
}

output "self_link" {
  value = google_compute_image.gce_image.self_link
}
