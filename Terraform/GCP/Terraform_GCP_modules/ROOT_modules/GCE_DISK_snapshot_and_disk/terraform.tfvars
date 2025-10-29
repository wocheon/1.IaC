### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### Snapshot Configurations ###
snapshot_name     = "terraform-test-snapshot"
snapshot_source_disk       = "gcp-ansible-test"
snapshot_source_disk_zone  = "asia-northeast3-c"
snapshot_storage_locations = "asia-northeast3"


### Boot_disk Configurations ###
new_disk_name = "gce-terraform-disk-test"
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
