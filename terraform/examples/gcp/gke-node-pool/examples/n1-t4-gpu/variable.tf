variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "asia-northeast3"
}
variable "cluster_name" { type = string }
variable "cluster_location" {
  type    = string
  default = "asia-northeast3"
}

variable "node_pool" {
  type = object({
    name               = string
    node_locations     = optional(list(string))
    node_count         = optional(number, 1)
    max_pods_per_node  = optional(number)
    kubernetes_version = optional(string)
    deletion_policy    = optional(string, "PREVENT")
  })
}

variable "autoscaling" {
  type = object({ enabled = bool, use_total_limits = bool, min_nodes = number, max_nodes = number, location_policy = string })
  validation {
    condition     = var.autoscaling.min_nodes <= var.autoscaling.max_nodes
    error_message = "min_nodes는 max_nodes 이하여야 합니다."
  }
}

variable "management" {
  type = object({
    auto_repair     = optional(bool, true)
    auto_upgrade    = optional(bool, true)
    max_surge       = optional(number, 1)
    max_unavailable = optional(number, 0)
  })
  default = {}
}

variable "node_drain_config" {
  type    = object({ grace_termination_duration = string, pdb_timeout_duration = string, respect_pdb_during_node_pool_deletion = bool })
  default = null
}
variable "network_config" {
  type    = object({ create_pod_range = bool, enable_private_nodes = optional(bool), pod_ipv4_cidr_block = optional(string), pod_range = optional(string), subnetwork = optional(string) })
  default = null
}

variable "node_config" {
  type = object({
    machine_type    = string
    image_type      = optional(string, "COS_CONTAINERD")
    spot            = optional(bool, false)
    preemptible     = optional(bool, false)
    service_account = optional(string)
    oauth_scopes    = optional(list(string))
    boot_disk = optional(object({
      size_gb                = optional(number, 100)
      disk_type              = optional(string, "pd-balanced")
      provisioned_iops       = optional(number)
      provisioned_throughput = optional(number)
    }), {})
    boot_disk_kms_key = optional(string)
    min_cpu_platform  = optional(string)
    local_ssd_count   = optional(number, 0)
    logging_variant   = optional(string, "DEFAULT")
  })
  validation {
    condition     = startswith(var.node_config.machine_type, "n1-")
    error_message = "T4 프로필은 n1-* 머신 타입을 사용해야 합니다."
  }
}

variable "gpu" {
  type = object({
    type           = optional(string, "nvidia-tesla-t4")
    count          = optional(number, 1)
    driver_version = optional(string, "DEFAULT")
    sharing        = optional(object({ strategy = string, max_clients = number }))
  })
  default = {}
  validation {
    condition     = var.gpu.type == "nvidia-tesla-t4"
    error_message = "이 프로필의 GPU type은 nvidia-tesla-t4여야 합니다."
  }
}

variable "kubernetes_labels" {
  type    = map(string)
  default = {}
}
variable "kubernetes_taints" {
  type    = list(object({ key = string, value = string, effect = string }))
  default = []
}
variable "network_tags" {
  type    = list(string)
  default = []
}
variable "resource_labels" {
  type    = map(string)
  default = {}
}
variable "resource_manager_tags" {
  type    = map(string)
  default = {}
}
variable "instance_metadata" {
  type    = map(string)
  default = null
}
variable "security" {
  type = object({
    enable_secure_boot          = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
  })
  default = {}
}
variable "workload_metadata_mode" {
  type    = string
  default = "GKE_METADATA"
}
variable "enable_gvnic" {
  type    = bool
  default = null
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
  type    = object({ cpu_manager_policy = string, cpu_cfs_quota = bool, pod_pids_limit = number, insecure_readonly_port = string })
  default = null
}
variable "linux_node_config" {
  type    = object({ cgroup_mode = string, sysctls = map(string) })
  default = null
}
