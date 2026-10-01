resource "google_container_cluster" "primary" {
  provider = google

  #### 기본 설정 ####
  name            = var.gke_cluster_name
  description     = var.gke_cluster_description
  project         = var.project
  location        = var.gke_cluster_location
  node_locations  = var.gke_cluster_node_locations
  resource_labels = var.gke_cluster_resource_labels
  network         = var.gke_cluster_network
  subnetwork      = var.gke_cluster_subnetwork
  cluster_ipv4_cidr = var.cluster_ipv4_cidr
  deletion_protection = var.gke_cluster_deletion_protection
  min_master_version      = var.gke_cluster_master_version

  # 기본 노드풀 삭제
  initial_node_count       = 1
  remove_default_node_pool = true

  #### 클러스터 인증 및 보안 설정 ####
  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }

  dynamic "secret_manager_config" {
    for_each = var.enable_secret_manager_addon ? [var.enable_secret_manager_addon] : []
    content {
      enabled = secret_manager_config.value
    }
  }

  #### 클러스터 기능 설정 ####
  enable_intranode_visibility = var.enable_intranode_visibility
  enable_kubernetes_alpha     = var.enable_kubernetes_alpha


  #### 네트워크 정책 ####
  dynamic "network_policy" {
    for_each = var.cluster_network_policy
    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }

  enable_fqdn_network_policy   = var.enable_fqdn_network_policy

  #### Gateway API 설정 ####
  dynamic "gateway_api_config" {
    for_each = var.gateway_api_config
    content {
      channel = gateway_api_config.value.channel
    }
  }

  #### 비용 관리 설정 ####
  dynamic "cost_management_config" {
    for_each = var.enable_cost_allocation ? [1] : []
    content {
      enabled = true
    }
  }

  #### 유지보수(maintenance) 설정 ####
  dynamic "maintenance_policy" {
    for_each = (var.maintenance_window != null || length(var.maintenance_exclusions) > 0) ? [1] : []
    content {
      # Daily maintenance window가 지정되었을 때만 설정되도록
      dynamic "recurring_window" {
        for_each = var.maintenance_window != null ? [var.maintenance_window] : []
        content {
            start_time = recurring_window.value.start_time
            end_time   = recurring_window.value.end_time
            recurrence = recurring_window.value.recurrence
          }
      }
      # Maintenance exclusion이 지정되었을 때만 설정되도록
      dynamic "maintenance_exclusion" {
        for_each = length(var.maintenance_exclusions) > 0 ? var.maintenance_exclusions : {}
        content {
          exclusion_name  = maintenance_exclusion.key
          start_time      = maintenance_exclusion.value.start_time
          end_time        = maintenance_exclusion.value.end_time
          exclusion_options {
            scope = maintenance_exclusion.value.exclusion_scope
          }
        }
      }
    }
  }


  #### 릴리스 채널 설정 ####
  dynamic "release_channel" {
    for_each = var.release_channel != null ? [var.release_channel] : ["reguler"]
    content {
      channel = release_channel.value
    }
  }
}