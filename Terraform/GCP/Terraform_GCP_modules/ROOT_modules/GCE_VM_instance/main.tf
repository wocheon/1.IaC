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

module "gce_instance" {
  source = "../modules/gce_instance"
  vm_name                   = var.vm_name
  machine_type              = var.machine_type
  zone                      = var.zone
  vm_labels                 = var.vm_labels
  boot_disk_image           = var.boot_disk_image
  boot_disk_snapshot        = var.boot_disk_snapshot
  boot_disk_size            = var.boot_disk_size
  boot_disk_type            = var.boot_disk_type
  boot_disk_labels          = var.boot_disk_labels
  network                   = var.network
  subnetwork                = var.subnetwork
  internal_ip               = var.internal_ip
  network_tags              = var.network_tags
  service_account           = var.service_account
  service_scope             = var.service_scope
  service_scope_list        = var.service_scope_list

### Default Values ###
#  vm_status                 = var.status                       # Default : RUNNING
#  auto_restart              = var.auto_restart                 # Default : true
#  boot_disk_auto_delete     = var.boot_disk_auto_delete        # Default : true
#  on_host_maintenance       = var.on_host_maintenance          # Default : MIGRATE
  use_external_ip           = var.use_external_ip              # Default : true
  external_ip_tier          = var.external_ip_tier             # Default : STANDARD

### Additional Disk Settings ###
#  enable_additional_disks   = var.enable_additional_disks       # Default : false
#  additional_disks          = module.gce_disk_empty[*].disk_id  # Depend On : enable_additional_disks

### GPU Accelerator Settings ###
# use_gpu_accelerator    =  var.use_gpu_accelerator              # Default : false
# gpu_type               =  var.gpu_type
# gpu_cnt                =  var.gpu_cnt

}


output "instance_name"{
  value = module.gce_instance.instance_name
}

output "instance_zone"{
  value = module.gce_instance.instance_zone
}

output "internal_ip"{
  value = module.gce_instance.internal_ip
}

output "external_ip"{
  value = module.gce_instance.external_ip
}

