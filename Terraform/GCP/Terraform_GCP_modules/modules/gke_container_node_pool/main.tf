resource "google_container_node_pool" "pools" {
  provider = google
  for_each = var.gke_container_node_pools

  name     = each.key
  project  = var.node_pool_project
  location = var.node_pool_location
  cluster  = var.gke_cluster_id

  node_locations = try(each.value.node_pool_node_locations, null)

  version = (
    lookup(each.value, "node_pool_auto_upgrade", var.node_pool_default_auto_upgrade)
    ? null
    : lookup(each.value, "version", var.gke_cluster_version)
  )

  initial_node_count = (
    each.value.node_pool_autoscaling != null
    ? try(each.value.node_pool_initial_node_count, try(each.value.node_pool_autoscaling.node_pool_min_count, 1))
    : null
  )

  node_count = (
    each.value.node_pool_autoscaling != null
    ? null
    : try(each.value.node_pool_node_count, 1)
  )

  max_pods_per_node = lookup(each.value, "node_pool_max_pods_per_node", null)

  dynamic "autoscaling" {
    for_each = each.value.node_pool_autoscaling != null ? [each.value.node_pool_autoscaling] : []
    content {
      # 위치 정책 (ANY/BALANCED)
      location_policy      = try(autoscaling.value.node_pool_location_policy, null)
      
      # 크기 한도 유형 (둘중 하나만 사용가능)
      ## 영역별 한도
      min_node_count       = try(autoscaling.value.node_pool_min_count, 1)
      max_node_count       = try(autoscaling.value.node_pool_max_count, 100)
      ## 총 한도
      total_min_node_count = try(autoscaling.value.node_pool_total_min_node_count, null)
      total_max_node_count = try(autoscaling.value.node_pool_total_max_node_count, null)
    }
  }

  management {
    auto_repair  = lookup(each.value, "node_pool_auto_repair", true)
    auto_upgrade = lookup(each.value, "node_pool_auto_upgrade", var.node_pool_default_auto_upgrade)
  }

  node_config {
    machine_type = lookup(each.value, "node_pool_machine_type", "e2-medium")
    disk_size_gb = lookup(each.value, "node_pool_disk_size_gb", "30")
    disk_type  = lookup(each.value, "node_pool_disk_type", "pd-balanced")
    image_type = lookup(each.value, "node_pool_image_type", "COS")

    labels = merge(
      var.node_pool_default_node_labels,
      lookup(each.value, "node_pool_labels", {})
    )

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = lookup(each.value, "node_pool_tags", null)

    service_account = lookup(each.value, "node_pool_sa_account", null)
    
    oauth_scopes = try(each.value.node_pool_oauth_scopes, [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ])

    dynamic "taint" {
      for_each = each.value.node_pool_taints != null ? each.value.node_pool_taints : []
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

    # Taint 설정 블록 추가

  

  # 업그레이드 전략 설정 추가
  upgrade_settings {
    max_surge       = try(each.value.node_pool_upgrade_settings.max_surge, 1)
    max_unavailable = try(each.value.node_pool_upgrade_settings.max_unavailable, 0)
  }
  
}
