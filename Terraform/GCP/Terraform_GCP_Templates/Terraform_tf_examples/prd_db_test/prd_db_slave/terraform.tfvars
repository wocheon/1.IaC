### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"


### VM General Configurations ###
#vm_name = "terraform-test"
vm_name = "prd-db-slave"
machine_type  = "e2-small"
vm_status = "RUNNING"
auto_restart = true

vm_labels = {
  type  = "gcevm"
  usage = "test-db"
  user  = "wocheon07"
  provider  = "terraform"
}

### Boot_disk Configurations ###

#boot_disk_image = "centos-mariadb-image"
#boot_disk_image = "ubuntu-2004-focal-v20240830"
#boot_disk_image = "ubuntu-2004-default-image"
boot_disk_image = "db-base-image-241011"
boot_disk_size = 30	#number
boot_disk_type = "pd-standard"
boot_disk_auto_delete = true

boot_disk_labels = {
   type = "gce-boot-disk"
   user = "wocheon07"
}

### Network Configurations ###

network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
internal_ip = "192.168.1.211"

use_external_ip = true
external_ip_tier = "STANDARD"

network_tags = [
	"work",
	"terraform-test"
]

### Additional Disk Configurations ### 
enable_additional_disks = false

additional_disks = [
	{ name = "add-disk-1" 
          size_gb = 20 
          type = "pd-standard" 
        },
        { name = "add-disk-2"
          size_gb = 30
          type = "pd-standard"
        }
]
### Service Scpoes List ### 


service_scope = "default"

service_scope_list = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/devstorage.full_control",
  "https://www.googleapis.com/auth/cloud-platform" 
]

#default_scope_list = [
#   "https://www.googleapis.com/auth/devstorage.read_only",
#   "https://www.googleapis.com/auth/logging.write",
#   "https://www.googleapis.com/auth/monitoring.write",
#   "https://www.googleapis.com/auth/service.management.readonly",
#   "https://www.googleapis.com/auth/servicecontrol",
#   "https://www.googleapis.com/auth/trace.append"
#]
#
