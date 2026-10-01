### GCP Project&Region ###

variable "project" {
  type        = string
  default     = "test-project"
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  type        = string
  default     = "asia-northeast3-a"
}

### VM General Configurations ###

variable "vm_name" {
  type        = string
}


### image Configurations ###

variable "image_name" {
  type		= string
}
