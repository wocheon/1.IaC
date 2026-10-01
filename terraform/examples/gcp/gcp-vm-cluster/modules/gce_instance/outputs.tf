output "instance_id" {
  description = "The ID of the created instance"
  value       = google_compute_instance.gce_instance.id
}

output "instance_self_link" {
  description = "The self-link of the created instance"
  value       = google_compute_instance.gce_instance.self_link
}

output "instance_name" {
  description = "The name of the created instance"
  value       = google_compute_instance.gce_instance.name
}

output "instance_zone" {
  description = "The zone where the instance is deployed"
  value       = google_compute_instance.gce_instance.zone
}

output "internal_ip" {
  description = "The internal IP address of the instance"
  value       = google_compute_instance.gce_instance.network_interface[0].network_ip
}

output "external_ip" {
  description = "The external IP address of the instance (if assigned)"
  value       = length(google_compute_instance.gce_instance.network_interface[0].access_config) > 0 ? google_compute_instance.gce_instance.network_interface[0].access_config[0].nat_ip : null
}

output "boot_disk_id" {
  description = "The ID of the boot disk attached to the instance"
  value       = google_compute_instance.gce_instance.boot_disk[0].device_name
}

output "attached_disk_ids" {
  description = "List of IDs for additional attached disks"
  value       = [for disk in google_compute_instance.gce_instance.attached_disk : disk.device_name]
}

output "service_account_email" {
  description = "The email of the service account attached to the instance"
  value       = google_compute_instance.gce_instance.service_account[0].email
}
