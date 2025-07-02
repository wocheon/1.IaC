### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"

### Instance_Template Configurations ###
new_template_name              = "example-template"
new_template_machine_type      = "e2-medium"

new_template_labels            = { 
    env = "dev"
    team = "backend" 
}

use_gpu_accelerator            = false
#new_template_gpu_type          = ""
#new_template_gpu_cnt           = 0

new_template_disk_source_image = "packer-image-240919"
new_template_disk_auto_delete  = true
new_template_disk_size_gb      = 30
new_template_disk_type         = "pd-standard"

new_template_network           = "test-vpc-1"
new_template_subnetwork        = "test-vpc-sub-01"
use_external_ip                = true
new_template_external_ip_tier  = "PREMIUM"

new_template_network_tags      = ["web", "dev"]

service_account                = "487401709675-compute@developer.gserviceaccount.com"

service_scope                  = "default"
service_scope_list = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/devstorage.full_control",
  "https://www.googleapis.com/auth/cloud-platform" 
]

on_host_maintenance           = "MIGRATE"

new_template_auto_restart      = true