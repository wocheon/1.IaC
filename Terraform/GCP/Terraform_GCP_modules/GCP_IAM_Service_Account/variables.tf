### GCP Project&Region ###

variable "project" {
  type        = string
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

### GCP IAM Custom Role Configurations ###

variable "role_id" { type = string }
variable "role_title" { type = string }
variable "role_description" { type = string }
variable "role_permissions" { type = list(string) }
#variable "role_project_id" { type = string }
variable "role_stage" { 
    type = string
    default = "GA"
}

### GCP IAM Service_account Configurations ### 

variable "new_service_account_id" { type = string }
variable "new_service_account_display_name" { type = string }
variable "new_service_account_description" { type = string }
#variable "new_service_account_project_id" { type = string }