variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}

variable "bucket_location" {
  description = "The location of the bucket."
  type        = string
}

variable "bucket_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "bucket_storage_class" {
  description = "Bucket's Storage Class"
  type        = string
  default     = "STANDARD"
}

variable "bucket_uniform_bucket_level_access" {
  description = "Enforce uniform bucket-level access."
  type        = bool
  default     = false
}

variable "bucket_force_destroy" {
  description = "Allow destroying the bucket even if it contains objects."
  type        = bool
  default     = true
}

variable "bucket_versioning" {
  description = "Enable object versioning."
  type        = bool
  default     = false
}

variable "bucket_lifecycle_age_days" {
  description = "Delete objects older than this many days."
  type        = number
  default     = null
}

variable "bucket_labels" {
  description = "Labels to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "bucket_soft_delete_policy_days" {
  description = "Retention period (in days) for soft delete policy. If null, no retention policy is applied."
  type        = number
  default     = 0
}
