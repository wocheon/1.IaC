### GCP Project&Region ###

variable "project" {
  type        = string
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  type        = string
  default     = "asia-northeast3-c"
}

variable "today_date" {
  type        = string
  default     = ""
}

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