### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### VM General Configurations ###
vm_name = "terraform-test"
machine_type  = "e2-small"
vm_status = "RUNNING"
auto_restart = true

vm_labels = {
  type  = "gcevm"
  usage = "test-db"
  user  = "wocheon07"
  provider  = "terraform"
}

on_host_maintenance = "TERMINATE"

### gpu configurations ###
use_gpu_accelerator     = false
#gpu_type                = "nvidia-tesla-t4"
#gpu_cnt                 = 1


### Boot_disk Configurations ###

boot_disk_image = "packer-image-240919"
boot_disk_snapshot = null

boot_disk_size = 30	#number
boot_disk_type = "pd-standard"
boot_disk_auto_delete = true

boot_disk_labels = {
   type = "gce-boot-disk"
   user = "wocheon07"
}

### additional_disk Configurations ###
enable_additional_disks = true

new_disk_name = "gce-additional-disk-01"
new_disk_size = 30      #number
new_disk_type = "pd-standard"
new_disk_zone = "asia-northeast3-a"

new_disk_labels = {
   type = "gce-addtional-disk"
   user = "wocheon07"
}

### additional_disk Source Configurations ###
# 둘중 Null이 아닌 값을 찾아 사용
new_disk_image_id       = null
new_disk_snapshot_id    = null


### Network Configurations ###

network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
internal_ip = "192.168.1.102"

use_external_ip = true
external_ip_tier = "STANDARD"

network_tags = [
	"work",
	"terraform-test"
]

### Service Scpoes List ### 

service_account = "487401709675-compute@developer.gserviceaccount.com"

#service_scope = "default"
service_scope = "selected"

service_scope_list = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/devstorage.full_control",
  "https://www.googleapis.com/auth/cloud-platform" 
]



