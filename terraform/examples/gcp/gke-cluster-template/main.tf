terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }

  required_version = ">= 1.0"
}

provider "google" {
  project = var.gke_gcp_project
  region  = var.gke_subnetwork_region
  zone    = var.gke_zone
}

resource "google_container_cluster" "primary" {
  name               = var.gke_cluster_name
  location           = var.gke_zone
  network            = var.gke_network
  subnetwork         = var.gke_subnetwork
  min_master_version = var.gke_version
  deletion_protection = false
  
  remove_default_node_pool = true
  initial_node_count       = 1
  #wait_for_cluster	   = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = var.gke_node_pool_name
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_node_count
  #wait_for_node_pool = false

  node_config {
    machine_type = var.gke_node_machine_type
    disk_size_gb = var.gke_node_bootdisk_size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}
