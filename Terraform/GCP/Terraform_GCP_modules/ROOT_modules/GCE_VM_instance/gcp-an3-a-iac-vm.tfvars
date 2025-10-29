### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### VM General Configurations ###
vm_name = "gcp-an3-a-iac-vm"
machine_type  = "e2-medium"
vm_status = "RUNNING"
auto_restart = true

vm_labels = {
  type  = "gcevm"
  usage = "iac-vm"
  user  = "wocheon07"  
}

### gpu configurations ###
use_gpu_accelerator     = false
#gpu_type                = "nvidia-tesla-t4"
#gpu_cnt                 = 1


### Boot_disk Configurations ###
boot_disk_image = "ubuntu-2204-jammy-v20250409"
#boot_disk_snapshot = "docker-snapshot-001"
boot_disk_snapshot = null

boot_disk_size = 50	#number
boot_disk_type = "pd-balanced"
boot_disk_auto_delete = true

boot_disk_labels = {
   type = "gce-boot-disk"
   user = "wocheon07"
   bootdisk = "gcp-an3-a-iac-vm"
}

### additional_disk Configurations ###
enable_additional_disks = false

#new_disk_name = "gce-additional-disk-01"
#new_disk_size = 30      #number
#new_disk_type = "pd-standard"
#new_disk_zone = "asia-northeast3-a"
#
#new_disk_labels = {
#   type = "gce-addtional-disk"
#   user = "wocheon07"
#}

### Network Configurations ###

network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
internal_ip = "192.168.1.100"

use_external_ip = true
external_ip_tier = "STANDARD"

network_tags = [
	"iac-tool-vm",
	"kubectl"
]

### Service Scpoes List ### 

service_account = "terraform-custom-sa@test-project.iam.gserviceaccount.com"

#service_scope = "default"
service_scope = "selected"

service_scope_list = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/devstorage.full_control",
  "https://www.googleapis.com/auth/cloud-platform" 
]
