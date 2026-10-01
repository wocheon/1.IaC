### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"

### GKE Cluster Default Configurations ###

gke_cluster_name                = "test-gke-cluster"
#gke_cluster_master_version      = "1.30.9-gke.1009000"
gke_cluster_description         = "Terraform GKE Cluster Module Test"
gke_cluster_location            = "asia-northeast3-a"
#gke_cluster_node_locations      = ["asia-northeast3-a", "asia-northeast3-b"]
gke_cluster_network             = "test-vpc-1"
gke_cluster_subnetwork          = "test-vpc-sub-01"
gke_cluster_deletion_protection = false

### GKE Cluster Maintenance Configurations ###

#maintenance_window = {
#  start_time = "2019-01-01T09:00:00Z"
#  end_time   = "2019-01-01T17:00:00Z"
#  recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
#}
#
#maintenance_exclusions = {
#  "exclusion_1" = {
#    start_time      = "2025-05-01T00:00:00Z"
#    end_time        = "2025-05-01T01:00:00Z"
#    exclusion_scope = "NO_UPGRADES"
#  }
#  "exclusion_2" = {
#    start_time      = "2025-06-01T00:00:00Z"
#    end_time        = "2025-06-01T01:00:00Z"
#    exclusion_scope = "NO_UPGRADES"
#  }
#}


### GKE Node_pools Configurations ###

gke_container_node_pools = {
  test-node-pool1 = {
    node_pool_node_locations   = ["asia-northeast3-a"]
    node_pool_gke_version      = "1.30.9-gke.1009000" 
    node_pool_initial_node_count = 1   
    #node_pool_max_pods_per_node  = 100
    
    node_pool_autoscaling = {
      node_pool_location_policy    = "ANY" 
      #node_pool_min_count          = null
      #node_pool_max_count          = null
      total_min_count    = 0
      total_max_count    = 2
    }
    
    # node_configs
    node_pool_machine_type     = "e2-small"
    node_pool_disk_size_gb     = 30
    node_pool_disk_type        = "pd-balanced"
    node_pool_image_type       = "COS_CONTAINERD"
    
    node_pool_taints           = [
      { key   : "use-gpu", value : "false", effect : "NO_SCHEDULE" }
#      ,{ key   : "env", value : "production", effect : "PREFER_NO_SCHEDULE" }
    ]
    
    upgrade_settings = { max_surge = 1, max_unavailable = 0 }
    node_pool_labels = { workload : "web" }
    node_pool_tags             = ["web"]
    node_pool_auto_repair      = true
    node_pool_auto_upgrade     = true
    node_pool_sa_account       = "terraform-custom-sa@test-project.iam.gserviceaccount.com"

    node_pool_oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.full_control",
      "https://www.googleapis.com/auth/cloud-platform" 
    ]

  }
}
