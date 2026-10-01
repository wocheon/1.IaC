output "cluster_id" {
  description = "The id of the GKE cluster."
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = google_container_cluster.primary.endpoint
}

output "cluster_master_version" {
  description = "The master version of the GKE cluster."
  value       = google_container_cluster.primary.master_version
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate."
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
}

output "cluster_location" {
  description = "The location of the GKE cluster."
  value       = google_container_cluster.primary.location
}

output "cluster_network" {
  description = "The network used by the GKE cluster."
  value       = google_container_cluster.primary.network
}

output "cluster_subnetwork" {
  description = "The subnetwork used by the GKE cluster."
  value       = google_container_cluster.primary.subnetwork
}
