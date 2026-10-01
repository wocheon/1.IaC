### Snapshot Configurations ###

variable "snapshot_name" {
  type        = string
  default     = ""
}

variable "snapshot_source_disk" {
  type        = string
  default     = ""
}

variable "snapshot_source_disk_zone" {
  type        = string
  default     = ""
}

variable "snapshot_storage_locations" {
  type        = string
  default     = ""
}