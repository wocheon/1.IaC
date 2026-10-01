terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7"
    }
  }
}

data "google_container_cluster" "existing" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.cluster_location
}

resource "google_container_node_pool" "this" {
  project                   = var.project_id
  location                  = var.cluster_location
  cluster                   = data.google_container_cluster.existing.name
  name                      = var.node_pool_name
  node_locations            = var.node_locations
  node_count                = var.autoscaling.enabled ? null : var.node_count
  max_pods_per_node         = var.max_pods_per_node
  version                   = var.kubernetes_version
  ignore_node_count_changes = var.autoscaling.enabled
  deletion_policy           = var.deletion_policy

  dynamic "autoscaling" {
    for_each = var.autoscaling.enabled ? [var.autoscaling] : []
    content {
      min_node_count       = autoscaling.value.use_total_limits ? null : autoscaling.value.min_nodes
      max_node_count       = autoscaling.value.use_total_limits ? null : autoscaling.value.max_nodes
      total_min_node_count = autoscaling.value.use_total_limits ? autoscaling.value.min_nodes : null
      total_max_node_count = autoscaling.value.use_total_limits ? autoscaling.value.max_nodes : null
      location_policy      = autoscaling.value.location_policy
    }
  }

  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }

  dynamic "node_drain_config" {
    for_each = var.node_drain_config == null ? [] : [var.node_drain_config]
    content {
      grace_termination_duration            = node_drain_config.value.grace_termination_duration
      pdb_timeout_duration                  = node_drain_config.value.pdb_timeout_duration
      respect_pdb_during_node_pool_deletion = node_drain_config.value.respect_pdb_during_node_pool_deletion
    }
  }

  dynamic "network_config" {
    for_each = var.network_config == null ? [] : [var.network_config]
    content {
      create_pod_range     = network_config.value.create_pod_range
      enable_private_nodes = network_config.value.enable_private_nodes
      pod_ipv4_cidr_block  = network_config.value.pod_ipv4_cidr_block
      pod_range            = network_config.value.pod_range
      subnetwork           = network_config.value.subnetwork
    }
  }

  node_config {
    machine_type    = var.machine_type
    image_type      = var.image_type
    spot            = var.spot
    preemptible     = var.preemptible
    service_account = var.service_account
    oauth_scopes    = var.oauth_scopes

    # 사용자가 자주 수정하는 세 설정
    labels = var.kubernetes_labels
    dynamic "taint" {
      for_each = var.kubernetes_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    tags = var.network_tags

    resource_labels       = var.resource_labels
    resource_manager_tags = var.resource_manager_tags

    # metadata를 지정하지 않으면 GKE API 기본값을 그대로 사용한다.
    # 사용자 메타데이터를 지정하는 경우에는 legacy metadata endpoint가
    # 의도치 않게 다시 활성화되지 않도록 보안 기본값을 함께 넣는다.
    metadata = var.instance_metadata == null ? null : merge(
      { "disable-legacy-endpoints" = "true" },
      var.instance_metadata,
    )
    min_cpu_platform  = var.min_cpu_platform
    local_ssd_count   = var.local_ssd_count
    logging_variant   = var.logging_variant
    boot_disk_kms_key = var.boot_disk_kms_key

    boot_disk {
      size_gb                = var.boot_disk.size_gb
      disk_type              = var.boot_disk.disk_type
      provisioned_iops       = var.boot_disk.provisioned_iops
      provisioned_throughput = var.boot_disk.provisioned_throughput
    }

    dynamic "guest_accelerator" {
      for_each = var.gpu == null ? [] : [var.gpu]
      content {
        type  = guest_accelerator.value.type
        count = guest_accelerator.value.count

        gpu_driver_installation_config {
          gpu_driver_version = guest_accelerator.value.driver_version
        }

        dynamic "gpu_sharing_config" {
          for_each = guest_accelerator.value.sharing == null ? [] : [guest_accelerator.value.sharing]
          content {
            gpu_sharing_strategy       = gpu_sharing_config.value.strategy
            max_shared_clients_per_gpu = gpu_sharing_config.value.max_clients
          }
        }
      }
    }

    shielded_instance_config {
      enable_secure_boot          = var.enable_secure_boot
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }

    workload_metadata_config {
      mode = var.workload_metadata_mode
    }

    dynamic "gvnic" {
      for_each = var.enable_gvnic == null ? [] : [1]
      content {
        enabled = var.enable_gvnic
      }
    }

    dynamic "gcfs_config" {
      for_each = var.enable_gcfs == null ? [] : [1]
      content {
        enabled = var.enable_gcfs
      }
    }

    dynamic "reservation_affinity" {
      for_each = var.reservation == null ? [] : [var.reservation]
      content {
        consume_reservation_type = reservation_affinity.value.consume_type
        key                      = reservation_affinity.value.key
        values                   = reservation_affinity.value.values
      }
    }

    dynamic "kubelet_config" {
      for_each = var.kubelet_config == null ? [] : [var.kubelet_config]
      content {
        cpu_manager_policy                     = kubelet_config.value.cpu_manager_policy
        cpu_cfs_quota                          = kubelet_config.value.cpu_cfs_quota
        pod_pids_limit                         = kubelet_config.value.pod_pids_limit
        insecure_kubelet_readonly_port_enabled = kubelet_config.value.insecure_readonly_port
      }
    }

    dynamic "linux_node_config" {
      for_each = var.linux_node_config == null ? [] : [var.linux_node_config]
      content {
        cgroup_mode = linux_node_config.value.cgroup_mode
        sysctls     = linux_node_config.value.sysctls
      }
    }
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = !var.spot || !var.preemptible
      error_message = "spot과 preemptible은 동시에 true일 수 없습니다."
    }
  }
}

output "id" {
  value = google_container_node_pool.this.id
}

output "managed_instance_group_urls" {
  value = google_container_node_pool.this.managed_instance_group_urls
}
