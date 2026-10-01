### GCP IAM Custom Role Configurations ###

variable "role_id" { type = string }
variable "role_title" { type = string }
variable "role_description" { type = string }
variable "role_permissions" { type = list(string) }
variable "role_project_id" { type = string }

variable "role_stage" { 
    type = string
    default = "GA"
}