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
variable "node_pool_project" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "node_pool_location" {
  description = "Location of the cluster (region or zone)"
  type        = string
}

variable "node_pool_default_auto_upgrade" {
  description = "Default value for auto upgrade in node pools"
  type        = bool
  default     = true
}

variable "node_pool_default_node_labels" {
  description = "Default labels for the nodes"
  type        = map(string)
  default     = {}
}

variable "gke_cluster_id" {
  type        = string
}
variable "gke_cluster_version" {  
  type        = string
}