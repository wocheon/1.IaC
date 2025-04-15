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
  new_image_name    = "${var.new_image_name}-${local.today_date}"
  new_image_source_disk       = var.new_image_source_disk
  new_image_source_snapshot   = var.new_image_source_snapshot
  new_image_storage_locations = var.new_image_storage_locations
}

 module "gce_disk" {
   source = "../modules/gce_disk"
   new_disk_name         = var.new_disk_name
   new_disk_zone         = var.new_disk_zone
   new_disk_type         = var.new_disk_type
 #  new_disk_size         = var.new_disk_size
   new_disk_size         = module.gce_image.disk_size_gb 
   new_disk_labels       = var.new_disk_labels
 ### Source Configurations ###
   new_disk_image_id     = module.gce_image.id
   new_disk_snapshot_id  = var.new_disk_snapshot_id   
 }

output "gce_disk_id" {
  description = "Show GCE disk ID"
  value       = module.gce_disk.disk_id
}

output "gce_disk_self_link" {
  description = "Show GCE disk ID"
  value       = module.gce_disk.self_link
}
