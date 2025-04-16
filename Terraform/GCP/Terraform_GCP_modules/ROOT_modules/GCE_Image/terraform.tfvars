### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### Image Configurations ###
# Source_Disk는 VM에 할당되지 않거나, 중지된 VM의 디스크만 가능
# Source_Disk 는 Self Link로만 할당 가능
new_image_name    = "gcp-an3-a-iac-vm-image"
#new_image_source_disk       = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test"
new_image_source_disk       = null
new_image_source_snapshot   = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/global/snapshots/gcp-an3-a-iac-vm-snapshot-250415"
new_image_storage_locations = "asia-northeast3"
