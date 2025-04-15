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


module "iam_role_binding" {
  source = "../modules/gcp_iam_role_binding"  
  project = var.project 
  role    = var.role_id 
  service_account_email  = "serviceAccount:${var.service_account_email}"  
}
