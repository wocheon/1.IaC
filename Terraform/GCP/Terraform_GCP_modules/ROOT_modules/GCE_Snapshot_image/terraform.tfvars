### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### Snapshot Configurations ###
snapshot_name     = "gcp-an3-a-iac-vm-snapshot"       # 뒤에 자동으로 오늘날짜(ymd) 추가
snapshot_source_disk       = "gcp-an3-a-iac-vm"
snapshot_source_disk_zone  = "asia-northeast3-a"
snapshot_storage_locations = "asia-northeast3"

### Image Configurations ###
# Source_Disk는 VM에 할당되지 않거나, 중지된 VM의 디스크만 가능
# Source_Disk 는 Self Link로만 할당 가능
new_image_name    = "gcp-an3-a-iac-vm-image"
# source_disk       = null
new_image_source_disk       = null
new_image_source_snapshot   = null
new_image_storage_locations = "asia-northeast3"
