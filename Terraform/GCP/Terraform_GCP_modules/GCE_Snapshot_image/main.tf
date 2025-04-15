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

module "gce_disk_snapshot" {
  source = "../modules/gce_snapshot"
  snapshot_name     = "${var.snapshot_name}-${local.today_date}"    # Snapshot명-[오늘날짜(ymd)]
  snapshot_source_disk       = var.snapshot_source_disk
  snapshot_source_disk_zone  = var.snapshot_source_disk_zone
  snapshot_storage_locations = var.snapshot_storage_locations
}


module "gce_image" {
  source = "../modules/gce_image"
  new_image_name          = "${var.new_image_name}-${local.today_date}"
  new_image_source_disk   = var.new_image_source_disk
  new_image_source_snapshot         = module.gce_disk_snapshot.self_link
  new_image_storage_locations       = var.new_image_storage_locations
}


output "snapshot_id" {
  value = module.gce_disk_snapshot.snapshot_id
}

output "snapshot_disk_size_gb" {
  value = module.gce_disk_snapshot.disk_size_gb
}

output "snapshot_self_link" {
  value = module.gce_disk_snapshot.self_link
}



output "image_id" {
  value = module.gce_image.id
}

output "image_disk_size_gb" {
  value = module.gce_image.disk_size_gb
}

output "image_self_link" {
  value = module.gce_image.self_link
}

