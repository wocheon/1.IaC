### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### Image Configurations ### 
# Source_Disk는 VM에 할당되지 않거나, 중지된 VM의 디스크만 가능
# Source_Disk 는 Self Link로만 할당 가능
new_image_name    = "terraform-test-image"
new_image_source_disk       = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test"
new_image_source_snapshot   = null
new_image_storage_locations = "asia-northeast3"

### Boot_disk Configurations ###
new_disk_name = "gce-terraform-image-disk-test"
new_disk_size = 30	#number
new_disk_type = "pd-standard"
new_disk_zone = "asia-northeast3-a"

new_disk_labels = {
   type = "gce-boot-disk"
   user = "wocheon07"
}

### Source Configurations ###
new_disk_snapshot_id    = null
new_disk_image_id		   = null