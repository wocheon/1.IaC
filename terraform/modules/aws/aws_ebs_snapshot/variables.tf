variable "ebs_snapshot_volume_id" {
  description = "The ID of the EBS volume to snapshot"
  type        = string
}

variable "ebs_snapshot_description" {
  description = "A description for the snapshot"
  type        = string
  default     = "Snapshot created by Terraform"
}

variable "ebs_snapshot_storage_tier" {
  description = "Specifies the storage tier (standard or archive)"
  type        = string
  default     = "standard"
}

variable "ebs_snapshot_permanent_restore" {
  description = "Indicates whether to permanently restore a snapshot that was archived"
  type        = bool
  default     = false
}

variable "ebs_snapshot_temporary_restore_days" {
  description = "Number of days to temporarily restore a snapshot from the archive tier"
  type        = number
  default     = null
}

variable "ebs_snapshot_tags" {
  description = "Tags to assign to the snapshot"
  type        = map(string)
  default     = {}
}
