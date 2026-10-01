output "network_name" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc_network.self_link
}
