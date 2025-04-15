output "snapshot_id" {
  value = google_compute_snapshot.disk_snapshot.snapshot_id
}

output "disk_size_gb" {
  value = google_compute_snapshot.disk_snapshot.disk_size_gb
}

output "self_link" {
  value = google_compute_snapshot.disk_snapshot.self_link
}

