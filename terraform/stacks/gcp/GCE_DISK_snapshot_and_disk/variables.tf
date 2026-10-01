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



### BOOT_DISK Configurations ###

variable "new_disk_name" {
  type        = string
}

variable "new_disk_zone" {
  type        = string
}

variable "new_disk_size" {
  type        = number
}

variable "new_disk_type" {
  type        = string
  default     = "pd-standard"
}

variable "new_disk_labels" {
  type        = map(string)
  default     = { 
        type = "gce-boot-disk"
        user = "wocheon07"   
  } 
}

### Source Configurations ###

variable "new_disk_snapshot_id" {
  type        = string
  default     = ""
}

variable "new_disk_image_id" {
  type        = string
  default     = ""
}
