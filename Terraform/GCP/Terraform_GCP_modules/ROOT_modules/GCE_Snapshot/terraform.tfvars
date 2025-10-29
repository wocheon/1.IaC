### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

### Snapshot Configurations ###
snapshot_name     = "terraform-test-snapshot"       # 뒤에 자동으로 오늘날짜(ymd) 추가
snapshot_source_disk       = "gcp-ansible-test"
snapshot_source_disk_zone  = "asia-northeast3-c"
snapshot_storage_locations = "asia-northeast3"
