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

module "gcs_bucket" {
  source  = "../modules/gcs_storage_bucket"
  bucket_name                        = var.bucket_name
  bucket_storage_class               = var.bucket_storage_class
  bucket_location                    = var.region
  bucket_project_id                  = var.project
  bucket_labels                      = var.bucket_labels
  bucket_uniform_bucket_level_access = var.bucket_uniform_bucket_level_access
  bucket_force_destroy               = var.bucket_force_destroy
  bucket_versioning                  = var.bucket_versioning
  bucket_lifecycle_age_days          = var.bucket_lifecycle_age_days
  bucket_soft_delete_policy_days     = var.bucket_soft_delete_policy_days
}
