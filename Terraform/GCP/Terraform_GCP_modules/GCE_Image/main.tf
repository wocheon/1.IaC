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

locals {
  today_date = formatdate("YYMMDD", timestamp())
}

module "gce_image" {
  source = "../modules/gce_image"
  new_image_name          = "${var.new_image_name}-${local.today_date}"
  new_image_source_disk   = var.new_image_source_disk
  new_image_source_snapshot         = var.new_image_source_snapshot
  new_image_storage_locations       = var.new_image_storage_locations
}

output "id" {
  value = module.gce_image.id
}

output "disk_size_gb" {
  value = module.gce_image.disk_size_gb
}

output "self_link" {
  value = module.gce_image.self_link
}
