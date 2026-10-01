### GKE Cluster Default Values ###

variable "gke_cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "gke_cluster_description" {
  description = "Description of the GKE cluster."
  type        = string
  default     = ""
}

variable "project" {
  description = "The project ID to create the GKE cluster in."
  type        = string
}

variable "gke_cluster_location" {
  description = "The location (region or zone) for the GKE cluster."
  type        = string
}

variable "gke_cluster_node_locations" {
  description = "List of zones in which the cluster's nodes will be located."
  type        = list(string)
  default     = []
}

variable "gke_cluster_resource_labels" {
  description = "Resource labels to be applied to the cluster."
  type        = map(string)
  default     = {}
}

variable "gke_cluster_network" {
  description = "The name of the VPC network to host the cluster in."
  type        = string
}

variable "gke_cluster_subnetwork" {
  description = "The name of the subnetwork to host the cluster in."
  type        = string
}


variable "cluster_ipv4_cidr" {
  description = "The IP range for the cluster pods."
  type        = string
  default     = null
}

variable "gke_cluster_master_version" {
  description = "The Kubernetes version to use for the master."
  type        = string
  default     = null
}

variable "gke_cluster_deletion_protection" {
  description = "Whether or not to enable deletion protection on the cluster."
  type        = bool
  default     = false
}


### GKE Cluster Optional Variables ###

variable "enable_cost_allocation" {
  description = "Enable cost_allocation."
  type        = bool
  default     = false
}


variable "issue_client_certificate" {
  description = "Whether client certificates are issued."
  type        = bool
  default     = false
}

variable "enable_secret_manager_addon" {
  description = "Enable Secret Manager CSI Driver addon."
  type        = bool
  default     = false
}

variable "enable_intranode_visibility" {
  description = "Enable intra-node visibility."
  type        = bool
  default     = false
}

variable "enable_kubernetes_alpha" {
  description = "Enable Kubernetes alpha features on the cluster."
  type        = bool
  default     = false
}

variable "cluster_network_policy" {
  description = "Network policy configuration for the cluster."
  type = list(object({
    enabled  = bool
    provider = string
  }))
  default = []
}

variable "enable_fqdn_network_policy" {
  description = "Enable FQDN network policy."
  type        = bool
  default     = false
}

variable "gateway_api_config" {
  description = "Gateway API configuration."
  type = list(object({
    channel = string
  }))
  default = []
}

variable "enable_cost_management" {
  description = "Enable cost management features."
  type        = bool
  default     = false
}

variable "cluster_secondary_range_name" {
  description = "The secondary range name for cluster IPs."
  type        = string
  default     = null
}

variable "services_secondary_range_name" {
  description = "The secondary range name for services IPs."
  type        = string
  default     = null
}

variable "cluster_dns" {
  description = "Cluster DNS provider (e.g., 'CLOUD_DNS')."
  type        = string
  default     = null
}

variable "cluster_dns_scope" {
  description = "Cluster DNS scope."
  type        = string
  default     = null
}

variable "cluster_dns_domain" {
  description = "Cluster DNS domain."
  type        = string
  default     = null
}

variable "logging_service" {
  description = "Logging service for the cluster."
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service for the cluster."
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "release_channel" {
  description = "Release channel to subscribe the cluster to."
  type        = string
  default     = "REGULAR"
}

variable "enable_workload_identity" {
  description = "Whether to enable Workload Identity."
  type        = bool
  default     = false
}


variable "maintenance_window" {
  description = "The daily maintenance window for the cluster."
  type = object({
    start_time = string
    end_time   = string
    recurrence = string
  })
  default = null  # null이면 해당 설정이 사용되지 않음
}

# maintenance_exclusions를 위한 변수
variable "maintenance_exclusions" {
  description = "A map of maintenance exclusions for the cluster."
  type = map(object({
    start_time        = string
    end_time          = string
    exclusion_scope   = string
  }))
  default = {}  # 기본값을 빈 맵으로 설정하면, exclusions가 없으면 사용되지 않음
}