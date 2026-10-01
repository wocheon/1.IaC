terraform {
  required_version = ">= 1.6.0"
  required_providers { google = { source = "hashicorp/google", version = "~> 7.7" } }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "node_pool" {
  # 이 예제를 저장소 루트로 복사한 뒤 실행하는 경로입니다.
  source = "../../modules/gke-node-pool"

  project_id         = var.project_id
  cluster_name       = var.cluster_name
  cluster_location   = var.cluster_location
  node_pool_name     = var.node_pool.name
  node_locations     = var.node_pool.node_locations
  node_count         = var.node_pool.node_count
  max_pods_per_node  = var.node_pool.max_pods_per_node
  kubernetes_version = var.node_pool.kubernetes_version
  deletion_policy    = var.node_pool.deletion_policy
  autoscaling        = var.autoscaling
  auto_repair        = var.management.auto_repair
  auto_upgrade       = var.management.auto_upgrade
  max_surge          = var.management.max_surge
  max_unavailable    = var.management.max_unavailable
  node_drain_config  = var.node_drain_config
  network_config     = var.network_config

  machine_type                = var.node_config.machine_type
  image_type                  = var.node_config.image_type
  spot                        = var.node_config.spot
  preemptible                 = var.node_config.preemptible
  service_account             = var.node_config.service_account
  oauth_scopes                = var.node_config.oauth_scopes
  boot_disk                   = var.node_config.boot_disk
  boot_disk_kms_key           = var.node_config.boot_disk_kms_key
  min_cpu_platform            = var.node_config.min_cpu_platform
  local_ssd_count             = var.node_config.local_ssd_count
  logging_variant             = var.node_config.logging_variant
  kubernetes_labels           = var.kubernetes_labels
  kubernetes_taints           = var.kubernetes_taints
  network_tags                = var.network_tags
  resource_labels             = var.resource_labels
  resource_manager_tags       = var.resource_manager_tags
  instance_metadata           = var.instance_metadata
  enable_secure_boot          = var.security.enable_secure_boot
  enable_integrity_monitoring = var.security.enable_integrity_monitoring
  workload_metadata_mode      = var.workload_metadata_mode
  enable_gvnic                = var.enable_gvnic
  enable_gcfs                 = var.enable_gcfs
  reservation                 = var.reservation
  kubelet_config              = var.kubelet_config
  linux_node_config           = var.linux_node_config

  gpu = null
}

output "node_pool_id" { value = module.node_pool.id }
