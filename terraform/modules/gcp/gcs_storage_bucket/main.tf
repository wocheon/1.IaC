resource "google_storage_bucket" "gcs_bucket" {
  name          = var.bucket_name
  location      = var.bucket_location
  project       = var.bucket_project_id
  storage_class = var.bucket_storage_class

  uniform_bucket_level_access = var.bucket_uniform_bucket_level_access
  force_destroy               = var.bucket_force_destroy

  versioning {
    enabled = var.bucket_versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.bucket_lifecycle_age_days != null ? [var.bucket_lifecycle_age_days] : []
    content {
      action {
        type = "Delete"
      }
      condition {
        age = lifecycle_rule.value
      }
    }
  }
  
  dynamic "soft_delete_policy" {
    for_each = var.bucket_soft_delete_policy_days != null ? [var.bucket_soft_delete_policy_days] : []
    content {
      retention_duration_seconds = soft_delete_policy.value * 86400
      # days → seconds 로 변환 (필수)
    }
  }  


  labels = var.bucket_labels != null ? var.bucket_labels : null  
}
