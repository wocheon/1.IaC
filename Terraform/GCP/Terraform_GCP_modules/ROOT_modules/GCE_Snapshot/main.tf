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

output "snapshot_id" {
  value = module.gce_disk_snapshot.snapshot_id
}

output "disk_size_gb" {
  value = module.gce_disk_snapshot.disk_size_gb
}

output "self_link" {
  value = module.gce_disk_snapshot.self_link
}

