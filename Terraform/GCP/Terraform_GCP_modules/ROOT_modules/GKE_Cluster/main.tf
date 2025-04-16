terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region  
}

module "gke_cluster" {
  source  = "../modules/gke_container_cluster"
  project                         = var.project
  gke_cluster_name                = var.gke_cluster_name
  gke_cluster_master_version      = var.gke_cluster_master_version  
  gke_cluster_description         = var.gke_cluster_description
  gke_cluster_location            = var.gke_cluster_location
  gke_cluster_node_locations      = var.gke_cluster_node_locations
  gke_cluster_resource_labels     = var.gke_cluster_resource_labels
  gke_cluster_network             = var.gke_cluster_network
  gke_cluster_subnetwork          = var.gke_cluster_subnetwork
  cluster_ipv4_cidr               = var.cluster_ipv4_cidr
  gke_cluster_deletion_protection = var.gke_cluster_deletion_protection
  maintenance_window              = var.maintenance_window
  maintenance_exclusions          = var.maintenance_exclusions
}  


module "gke_node_pool" {
  source  = "../modules/gke_container_node_pool"
  depends_on = [module.gke_cluster]
  node_pool_project   = var.project
  node_pool_location  = var.region  
  gke_cluster_id    = module.gke_cluster.cluster_id
  gke_cluster_version = module.gke_cluster.cluster_master_version
  gke_container_node_pools = var.gke_container_node_pools
  node_pool_default_node_labels = var.node_pool_default_node_labels
}
