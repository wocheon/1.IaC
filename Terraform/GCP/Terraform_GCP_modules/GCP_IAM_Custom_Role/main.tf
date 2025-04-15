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
#  credentials = file("terraform-custom-sa@gcp-in-ca.iam.gserviceaccount.com.json")
}

module "iam_custom_role" {
  source            = "../modules/gcp_iam_role"  
  role_id           = var.role_id
  role_title        = var.role_title
  role_description  = var.role_description
  role_permissions  = var.role_permissions
  role_project_id   = var.project
}
