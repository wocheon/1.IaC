### GCP Configurations ###

variable "project" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

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


### GKE Node_Pool Configurations


variable "gke_container_node_pools" {
  description = "Node pool configuration map"
  type = map(object({
    node_pool_node_locations      = optional(list(string))    
    node_pool_gke_version         = optional(string)
    node_pool_initial_node_count  = optional(number)
    node_pool_node_count          = optional(number)
    node_pool_max_pods_per_node   = optional(number)

    node_pool_autoscaling = optional(object({
      node_pool_min_count             = optional(number)
      node_pool_max_count             = optional(number)
      node_pool_location_policy       = optional(string)
      node_pool_total_min_node_count  = optional(number)
      node_pool_total_max_node_count  = optional(number)
    }))

    node_pool_machine_type          = optional(string)
    node_pool_disk_size_gb          = optional(number)
    node_pool_disk_type             = optional(string)
    node_pool_image_type            = optional(string)
    node_pool_labels                = optional(map(string))
    node_pool_tags                  = optional(list(string))
    node_pool_auto_repair           = optional(bool)
    node_pool_auto_upgrade          = optional(bool)
    node_pool_sa_account            = optional(string)
    node_pool_oauth_scopes          = optional(list(string))

    # Taint 설정 추가
    node_pool_taints  = optional(list(object({
      key     = string
      value   = string
      effect  = string
    })))

    # 업그레이드 전략 설정 추가
    node_pool_upgrade_settings = optional(object({
      max_surge       = number
      max_unavailable = number
    }))
  }))
}
variable "node_pool_default_node_labels" {
  description = "Default labels for the nodes"
  type        = map(string)
  default     = {}
}