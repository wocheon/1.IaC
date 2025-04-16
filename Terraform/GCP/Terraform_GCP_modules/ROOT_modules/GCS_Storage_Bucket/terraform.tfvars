### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"

### GCS Bucket Configurations ###
bucket_name                 = "terraform-test-bucket-wocheon07"
bucket_storage_class        = "NEARLINE"
bucket_labels = { type  = "gcs-bucket", usage = "test-vm", user  = "wocheon07" }
bucket_uniform_bucket_level_access  = false
bucket_force_destroy                = true
bucket_versioning                   = false
#bucket_lifecycle_age_days           = 30
#bucket_soft_delete_policy_days       = 7