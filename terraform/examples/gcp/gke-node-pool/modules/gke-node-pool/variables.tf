variable "project_id" { type = string }
variable "cluster_name" { type = string }
variable "cluster_location" { type = string }
variable "node_pool_name" { type = string }
variable "node_locations" {
  type    = list(string)
  default = null
}
variable "node_count" {
  type    = number
  default = 1
}
variable "max_pods_per_node" {
  type    = number
  default = null
}
variable "kubernetes_version" {
  type    = string
  default = null
}
variable "deletion_policy" {
  type    = string
  default = "PREVENT"
}

variable "autoscaling" {
  type = object({
    enabled          = bool
    use_total_limits = bool
    min_nodes        = number
    max_nodes        = number
    location_policy  = string
  })
}

variable "auto_repair" { type = bool }
variable "auto_upgrade" { type = bool }
variable "max_surge" { type = number }
variable "max_unavailable" { type = number }

variable "node_drain_config" {
  type = object({
    grace_termination_duration            = string
    pdb_timeout_duration                  = string
    respect_pdb_during_node_pool_deletion = bool
  })
  default = null
}

variable "network_config" {
  type = object({
    create_pod_range     = bool
    enable_private_nodes = optional(bool)
    pod_ipv4_cidr_block  = optional(string)
    pod_range            = optional(string)
    subnetwork           = optional(string)
  })
  default = null
}

variable "machine_type" { type = string }
variable "image_type" { type = string }
variable "spot" { type = bool }
variable "preemptible" { type = bool }
variable "service_account" {
  type    = string
  default = null
}
variable "oauth_scopes" {
  type    = list(string)
  default = null
}

variable "kubernetes_labels" { type = map(string) }
variable "kubernetes_taints" {
  type = list(object({ key = string, value = string, effect = string }))
  validation {
    condition     = alltrue([for item in var.kubernetes_taints : contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], item.effect)])
    error_message = "Taint effect가 올바르지 않습니다."
  }
}
variable "network_tags" { type = list(string) }
variable "resource_labels" {
  type    = map(string)
  default = {}
}
variable "resource_manager_tags" {
  type    = map(string)
  default = {}
}
variable "instance_metadata" {
  description = "null이면 metadata를 API에 보내지 않음. 맵을 지정하면 disable-legacy-endpoints=true를 자동 병합"
  type        = map(string)
  default     = null
}

variable "boot_disk" {
  type = object({
    size_gb                = number
    disk_type              = string
    provisioned_iops       = optional(number)
    provisioned_throughput = optional(number)
  })
}
variable "boot_disk_kms_key" {
  type    = string
  default = null
}
variable "min_cpu_platform" {
  type    = string
  default = null
}
variable "local_ssd_count" {
  type    = number
  default = 0
}
variable "logging_variant" {
  type    = string
  default = "DEFAULT"
}

variable "gpu" {
  type = object({
    type           = string
    count          = number
    driver_version = string
    sharing = optional(object({
      strategy    = string
      max_clients = number
    }))
  })
  default = null
}

variable "enable_secure_boot" { type = bool }
variable "enable_integrity_monitoring" { type = bool }
variable "workload_metadata_mode" { type = string }
variable "enable_gvnic" {
  description = "null이면 GKE/머신 타입 기본값을 사용하고 true/false이면 명시적으로 설정"
  type        = bool
  default     = null
}
variable "enable_gcfs" {
  type    = bool
  default = null
}

variable "reservation" {
  type    = object({ consume_type = string, key = optional(string), values = optional(list(string), []) })
  default = null
}

variable "kubelet_config" {
  type = object({
    cpu_manager_policy     = string
    cpu_cfs_quota          = bool
    pod_pids_limit         = number
    insecure_readonly_port = string
  })
  default = null
}

variable "linux_node_config" {
  type    = object({ cgroup_mode = string, sysctls = map(string) })
  default = null
}

variable "timeouts" {
  type    = object({ create = string, update = string, delete = string })
  default = { create = "60m", update = "60m", delete = "60m" }
}
