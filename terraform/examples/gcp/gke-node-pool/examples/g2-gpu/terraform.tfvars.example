# G2 + NVIDIA L4 노드풀 예제
# 이 파일과 같은 디렉터리의 main.tf, variable.tf를 저장소 루트로 복사해서 사용합니다.

# [필수: 기존 클러스터]
project_id   = "my-gcp-project"
cluster_name = "existing-gke-cluster"

# 기본 리전과 클러스터 위치는 모두 asia-northeast3입니다.
# 다른 리전 또는 zonal 클러스터를 사용할 때만 아래 값을 지정하세요.
# region           = "asia-northeast3"
# cluster_location = "asia-northeast3-a"

# [노드풀] 서울에서 G2/L4는 asia-northeast3-a/b에서 제공됩니다.
node_pool = {
  name           = "g2-l4-gpu-pool"
  node_locations = ["asia-northeast3-a"]

  # 아래 값은 생략 시 각각 1, GKE 기본값, 클러스터 버전, PREVENT를 사용합니다.
  # node_count         = 1 # autoscaling.enabled=false일 때 사용
  # max_pods_per_node  = 110
  # kubernetes_version = null
  # deletion_policy    = "PREVENT" # DELETE/PREVENT/ABANDON
}

# [자동 확장] use_total_limits=true면 여러 존을 합친 전체 노드 수 기준입니다.
autoscaling = {
  enabled          = true
  use_total_limits = true
  min_nodes        = 0
  max_nodes        = 3
  location_policy  = "ANY" # BALANCED 또는 ANY
}

# [복구/업그레이드] 아래 블록을 생략하면 true/true/1/0이 기본값입니다.
# management = {
#   auto_repair     = true
#   auto_upgrade    = true
#   max_surge       = 1
#   max_unavailable = 0
# }

# [머신/디스크] 생략된 항목은 COS_CONTAINERD, 일반 VM, 100GB pd-balanced를 사용합니다.
node_config = {
  machine_type = "g2-standard-4"

  # image_type      = "COS_CONTAINERD" # 또는 UBUNTU_CONTAINERD
  # spot            = false
  # preemptible     = false # spot과 동시에 true 불가
  # service_account = "gke-node@my-gcp-project.iam.gserviceaccount.com"
  # oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  # local_ssd_count = 0
  # logging_variant = "DEFAULT" # 또는 MAX_THROUGHPUT
  # boot_disk_kms_key = null # CMEK CryptoKey 전체 경로
  # min_cpu_platform  = null
  # boot_disk = {
  #   size_gb   = 150
  #   disk_type = "pd-balanced"
  # }
}

# [GPU] 생략 시 L4 1개와 DEFAULT 드라이버를 사용합니다.
# gpu = {
#   type           = "nvidia-l4"
#   count          = 1
#   driver_version = "DEFAULT" # DEFAULT/LATEST/INSTALLATION_DISABLED
#   sharing        = { strategy = "TIME_SHARING", max_clients = 2 }
# }

# [Kubernetes label] Pod nodeSelector/affinity에 사용합니다. 필요 없으면 {}.
kubernetes_labels = {
  workload = "gpu-l4"
}

# [Kubernetes taint] effect: NO_SCHEDULE/PREFER_NO_SCHEDULE/NO_EXECUTE. 필요 없으면 [].
kubernetes_taints = [
  { key = "nvidia.com/gpu", value = "present", effect = "NO_SCHEDULE" }
]

# [Compute Engine 네트워크 태그] 방화벽 규칙 target tag에 사용합니다. 필요 없으면 [].
network_tags = ["gke-node", "gpu-node"]

# [GCP 리소스 라벨] 빈 맵이면 사용자 리소스 라벨을 붙이지 않습니다.
resource_labels = {}

# Resource Manager 태그가 필요하면 지정합니다. 키/값은 namespaced name 또는 숫자 ID 형식입니다.
# resource_manager_tags = { "my-project/environment" = "production" }

# [GCE 인스턴스 메타데이터]
# 미지정 시 GKE API 기본값을 사용합니다. 값을 지정하면 모듈이
# disable-legacy-endpoints="true"를 자동으로 함께 넣습니다.
# instance_metadata = { node-purpose = "gpu-l4" }

# [보안/메타데이터 서버] 생략 시 Secure Boot/무결성 모니터링=true, mode=GKE_METADATA.
# security = { enable_secure_boot = true, enable_integrity_monitoring = true }
# workload_metadata_mode = "GKE_METADATA" # 클러스터에서 Workload Identity 사용 필요

# [선택 기능] 미지정(null)하면 GKE/머신 타입 기본 동작을 사용합니다.
# enable_gvnic = true
# enable_gcfs  = true

# [선택: 노드 드레인]
# node_drain_config = {
#   grace_termination_duration            = "60s"
#   pdb_timeout_duration                  = "300s"
#   respect_pdb_during_node_pool_deletion = true
# }

# [선택: 네트워크] 미지정 시 클러스터 기본값을 사용합니다.
# network_config = {
#   create_pod_range     = false
#   enable_private_nodes = true
#   pod_range            = "pods-range"
# }

# [선택: 예약/고급 OS 설정]
# reservation       = { consume_type = "ANY_RESERVATION" }
# kubelet_config    = { cpu_manager_policy = "none", cpu_cfs_quota = true, pod_pids_limit = 0, insecure_readonly_port = "FALSE" }
# linux_node_config = { cgroup_mode = "CGROUP_MODE_V2", sysctls = {} }
