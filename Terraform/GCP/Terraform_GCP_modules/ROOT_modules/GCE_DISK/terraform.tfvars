### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"

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
# 둘중 Null이 아닌 값을 찾아 사용
new_disk_image_id       = null
new_disk_snapshot_id    = null
#new_disk_image_id		   = "5684785941229355772"
#new_disk_snapshot_id    = "8732534544530120257"
