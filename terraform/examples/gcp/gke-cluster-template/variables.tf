variable "gke_gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "gke_version" {
  description = "The version of GKE"
  type        = string
}

variable "gke_zone" {
  description = "The zone where the cluster will be deployed"
  type        = string
}

variable "gke_network" {
  description = "The VPC network for the cluster"
  type        = string
}

variable "gke_subnetwork" {
  description = "The subnetwork for the cluster"
  type        = string
}

variable "gke_subnetwork_region" {
  description = "The region for the subnetwork"
  type        = string
}

variable "gke_node_pool_name" {
  description = "The name of the node pool"
  type        = string
}

variable "gke_node_count" {
  description = "The number of nodes in the node pool"
  type        = number
}

variable "gke_node_machine_type" {
  description = "The machine type for the node pool"
  type        = string
}

variable "gke_node_bootdisk_size" {
  description = "The boot disk size (in GB) for nodes"
  type        = number
}
