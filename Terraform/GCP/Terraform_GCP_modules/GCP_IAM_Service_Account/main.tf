terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "random_string" "random" {
  special          = false
  length           = 5
  min_lower        = 5
}

module "iam_custom_role" {
  source            = "../modules/gcp_iam_role"  
  role_id           = "${var.role_id}_${random_string.random.result}"
  role_title        = var.role_title
  role_description  = var.role_description
  role_permissions  = var.role_permissions
  role_project_id   = var.project
}

module "iam_service_account" {
  source = "../modules/gcp_iam_service_account"  
  new_service_account_id            = var.new_service_account_id
  new_service_account_display_name  = var.new_service_account_display_name
  new_service_account_description   = var.new_service_account_description
  new_service_account_project_id    = var.project  
}

module "iam_role_binding" {
  source = "../modules/gcp_iam_role_binding"  
  project = var.project 
  role    = module.iam_custom_role.role_id
  service_account_email  = "serviceAccount:${module.iam_service_account.service_account_email}"  
}

module "iam_service_account_key" {
  source = "../modules/gcp_iam_service_account_key"
  service_account_id      = module.iam_service_account.service_account_id
  service_account_email   = module.iam_service_account.service_account_email
}
