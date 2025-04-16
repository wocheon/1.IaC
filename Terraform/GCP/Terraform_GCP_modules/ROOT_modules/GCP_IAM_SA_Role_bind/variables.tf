### GCP Project&Region ###

variable "project" {
  type        = string
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

### GCP IAM SA Role Binding Configurations ###

variable "role_id" { type = string }
variable "service_account_email" { type = string }