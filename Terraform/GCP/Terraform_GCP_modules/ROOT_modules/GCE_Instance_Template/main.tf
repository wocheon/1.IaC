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

module "gce_instance_template" {
  source = "../modules/gce_instance_template"

  new_template_name              = var.new_template_name
  new_template_region            = var.region
  new_template_machine_type      = var.new_template_machine_type  
  new_template_labels            = var.new_template_labels
  use_gpu_accelerator            = var.use_gpu_accelerator
  new_template_gpu_type          = var.new_template_gpu_type
  new_template_gpu_cnt           = var.new_template_gpu_cnt
  new_template_disk_source_image = var.new_template_disk_source_image
  new_template_disk_auto_delete  = var.new_template_disk_auto_delete
  new_template_disk_size_gb      = var.new_template_disk_size_gb
  new_template_disk_type         = var.new_template_disk_type
  new_template_network           = var.new_template_network
  new_template_subnetwork        = var.new_template_subnetwork
  use_external_ip                = var.use_external_ip
  new_template_external_ip_tier  = var.new_template_external_ip_tier
  new_template_network_tags      = var.new_template_network_tags
  service_account                = var.service_account
  service_scope                  = var.service_scope
  service_scope_list             = var.service_scope_list
  default_scope_list             = var.default_scope_list
}
