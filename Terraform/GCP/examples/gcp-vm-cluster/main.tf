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

### GCP Project&Region ###

variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type = string
}

variable "service_account" {
  type = string
}

### VM General Configurations ###

variable "vm_name" {
  type = string
}

variable "control_plane_vm_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "vm_status" {
  type    = string
  default = "RUNNING"
}

variable "auto_restart" {
  type    = bool
  default = true
}

variable "vm_labels" {
  type = map(string)
}

### GPU Configurations ###

variable "use_gpu_accelerator" {
  type    = bool
  default = false
}

variable "gpu_type" {
  type    = string
  default = ""
}

variable "gpu_cnt" {
  type    = number
  default = 0
}

### BOOT_DISK Configurations ###

variable "boot_disk_image" {
  type = string
}

variable "boot_disk_snapshot" {
  type = string
}

variable "boot_disk_size" {
  type = number
}

variable "boot_disk_type" {
  type = string
}

variable "boot_disk_auto_delete" {
  type    = bool
  default = true
}

variable "boot_disk_labels" {
  type = map(string)
}

### Additional Disk Configurations ###

variable "enable_additional_disks" {
  type    = bool
  default = false
}

variable "additional_disks" {
  type    = list(string)
  default = []
}

### Network Configurations ###

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "internal_ip" {
  type = string
}

variable "use_external_ip" {
  type    = bool
  default = true
}

variable "external_ip_tier" {
  type    = string
  default = "STANDARD"
}

variable "network_tags" {
  type = list(string)
}

### Service Account Scopes ###

variable "service_scope" {
  type = string
}

variable "service_scope_list" {
  type = list(string)
}

variable "on_host_maintenance" {
  type    = string
  default = "MIGRATE"
}

### SSH Configurations ###

variable "ssh_user" {
  description = "VM account that accepts the current local account's SSH public key. Defaults to the current local username."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_public_key_path" {
  description = "Path to the current local account's SSH public key."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

locals {
  ssh_user       = var.ssh_user != null ? var.ssh_user : basename(pathexpand("~"))
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  ssh_metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "${local.ssh_user}:${local.ssh_public_key}"
  }
}

variable "default_scope_list" {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

module "gce_instance" {
  count = 2

  source = "./modules/gce_instance"

  vm_name                 = "${var.vm_name}${count.index + 1}"
  machine_type            = var.machine_type
  zone                    = var.zone
  vm_status               = var.vm_status
  auto_restart            = var.auto_restart
  vm_labels               = var.vm_labels
  use_gpu_accelerator     = var.use_gpu_accelerator
  gpu_type                = var.gpu_type
  gpu_cnt                 = var.gpu_cnt
  boot_disk_image         = var.boot_disk_image
  boot_disk_snapshot      = var.boot_disk_snapshot
  boot_disk_size          = var.boot_disk_size
  boot_disk_type          = var.boot_disk_type
  boot_disk_auto_delete   = var.boot_disk_auto_delete
  boot_disk_labels        = var.boot_disk_labels
  enable_additional_disks = var.enable_additional_disks
  additional_disks        = var.additional_disks
  network                 = var.network
  subnetwork              = var.subnetwork
  internal_ip             = cidrhost("${var.internal_ip}/24", tonumber(split(".", var.internal_ip)[3]) + count.index + 1)
  use_external_ip         = var.use_external_ip
  external_ip_tier        = var.external_ip_tier
  network_tags            = var.network_tags
  service_account         = var.service_account
  service_scope           = var.service_scope
  service_scope_list      = var.service_scope_list
  default_scope_list      = var.default_scope_list
  on_host_maintenance     = var.on_host_maintenance
  metadata                = local.ssh_metadata
}

module "gce_control_plane" {
  source = "./modules/gce_instance"

  vm_name                 = var.control_plane_vm_name
  machine_type            = var.machine_type
  zone                    = var.zone
  vm_status               = var.vm_status
  auto_restart            = var.auto_restart
  vm_labels               = var.vm_labels
  use_gpu_accelerator     = var.use_gpu_accelerator
  gpu_type                = var.gpu_type
  gpu_cnt                 = var.gpu_cnt
  boot_disk_image         = var.boot_disk_image
  boot_disk_snapshot      = var.boot_disk_snapshot
  boot_disk_size          = var.boot_disk_size
  boot_disk_type          = var.boot_disk_type
  boot_disk_auto_delete   = var.boot_disk_auto_delete
  boot_disk_labels        = var.boot_disk_labels
  enable_additional_disks = var.enable_additional_disks
  additional_disks        = var.additional_disks
  network                 = var.network
  subnetwork              = var.subnetwork
  internal_ip             = var.internal_ip
  use_external_ip         = var.use_external_ip
  external_ip_tier        = var.external_ip_tier
  network_tags            = var.network_tags
  service_account         = var.service_account
  service_scope           = var.service_scope
  service_scope_list      = var.service_scope_list
  default_scope_list      = var.default_scope_list
  on_host_maintenance     = var.on_host_maintenance
  metadata                = local.ssh_metadata
}

output "instance_name" {
  value = concat([module.gce_control_plane.instance_name], module.gce_instance[*].instance_name)
}

output "instance_zone" {
  value = concat([module.gce_control_plane.instance_zone], module.gce_instance[*].instance_zone)
}

output "internal_ip" {
  value = concat([module.gce_control_plane.internal_ip], module.gce_instance[*].internal_ip)
}

output "external_ip" {
  value = concat([module.gce_control_plane.external_ip], module.gce_instance[*].external_ip)
}
