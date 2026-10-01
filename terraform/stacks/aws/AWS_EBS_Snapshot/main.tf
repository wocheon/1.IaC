terraform {
  # Terraform Cloud Workspace
  cloud { 
    organization = "terraform_cloud_wocheon" 
    workspaces { 
      name = "terraform-cloud-workspace-aws-repo" 
    } 
  } 
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "ebs_volume" {
  source  = "app.terraform.io/terraform_cloud_wocheon/aws-module-registry/aws//modules/aws_ebs"
  version = "1.0.8"
  ebs_availability_zone = var.ebs_availability_zone
  ebs_size              = var.ebs_size
  ebs_type              = var.ebs_type
  ebs_iops              = var.ebs_iops
  ebs_throughput        = var.ebs_throughput
  ebs_encrypted         = var.ebs_encrypted
  ebs_kms_key_id        = var.ebs_kms_key_id
  ebs_tags              = var.ebs_tags
  ebs_source_snapshot   = var.ebs_source_snapshot
}


module "ebs_snapshot" {
  source  = "app.terraform.io/terraform_cloud_wocheon/aws-module-registry/aws//modules/aws_ebs_snapshot"
  version = "1.0.8"  
  #ebs_snapshot_volume_id              = var.ebs_snapshot_volume_id
  ebs_snapshot_volume_id              = module.ebs_volume.volume_id
  ebs_snapshot_description            = var.ebs_snapshot_description
  ebs_snapshot_storage_tier           = var.ebs_snapshot_storage_tier
  ebs_snapshot_permanent_restore      = var.ebs_snapshot_permanent_restore
  ebs_snapshot_temporary_restore_days = var.ebs_snapshot_temporary_restore_days
  ebs_snapshot_tags                   = var.ebs_snapshot_tags
}


output "ebs_volume_id" {
  value = module.ebs_volume.volume_id
}

output "snapshot_id" {
  description = "The ID of the created snapshot"
  value       = module.ebs_snapshot.snapshot_id
}