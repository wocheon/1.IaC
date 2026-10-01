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

### Image Configurations ###

variable "new_image_name" {
  type        = string
  default     = ""
}

variable "new_image_source_disk" {
  type        = string
  default     = ""
}

variable "new_image_source_snapshot" {
  type        = string
  default     = ""
}

variable "new_image_storage_locations" {
  type        = string
  default     = ""
}