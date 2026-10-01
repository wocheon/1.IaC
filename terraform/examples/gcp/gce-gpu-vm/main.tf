terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0, < 8.0.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast3"
}

variable "zone" {
  description = "N1 with T4 must be available in this zone."
  type        = string
  default     = "asia-northeast3-b"
}

variable "service_account" {
  type = string
}

variable "vm_name" {
  type    = string
  default = "gcp-an3-b-gpu-vm"
}

variable "machine_type" {
  description = "N1 machine type used with the attached T4 GPU."
  type        = string
  default     = "n1-standard-4"

  validation {
    condition     = startswith(var.machine_type, "n1-")
    error_message = "machine_type must use the N1 machine series."
  }
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
  type    = map(string)
  default = {}
}

variable "boot_disk_size" {
  type    = number
  default = 50
}

variable "boot_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "boot_disk_auto_delete" {
  type    = bool
  default = true
}

variable "boot_disk_labels" {
  type    = map(string)
  default = {}
}

variable "enable_additional_disks" {
  type    = bool
  default = false
}

variable "additional_disks" {
  type    = list(string)
  default = []
}

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
  default = "PREMIUM"
}

variable "network_tags" {
  type    = list(string)
  default = []
}

variable "service_scope_list" {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}

variable "ssh_user" {
  description = "VM account that accepts the current local account's SSH public key."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key registered on the VM."
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

module "gce_gpu_instance" {
  source = "../gce-vm-cluster/modules/gce_instance"

  vm_name               = var.vm_name
  machine_type          = var.machine_type
  zone                  = var.zone
  vm_status             = var.vm_status
  auto_restart          = var.auto_restart
  vm_labels             = var.vm_labels
  use_gpu_accelerator   = true
  gpu_type              = "nvidia-tesla-t4"
  gpu_cnt               = 1
  boot_disk_image       = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
  boot_disk_snapshot    = null
  boot_disk_size        = var.boot_disk_size
  boot_disk_type        = var.boot_disk_type
  boot_disk_auto_delete = var.boot_disk_auto_delete
  boot_disk_labels      = var.boot_disk_labels

  enable_additional_disks = var.enable_additional_disks
  additional_disks        = var.additional_disks

  network          = var.network
  subnetwork       = var.subnetwork
  internal_ip      = var.internal_ip
  use_external_ip  = var.use_external_ip
  external_ip_tier = var.external_ip_tier
  network_tags     = var.network_tags

  service_account     = var.service_account
  service_scope       = "selected"
  service_scope_list  = var.service_scope_list
  default_scope_list  = var.service_scope_list
  on_host_maintenance = "TERMINATE"
  metadata            = local.ssh_metadata
}

output "instance_name" {
  value = module.gce_gpu_instance.instance_name
}

output "instance_zone" {
  value = module.gce_gpu_instance.instance_zone
}

output "internal_ip" {
  value = module.gce_gpu_instance.internal_ip
}

output "external_ip" {
  value = module.gce_gpu_instance.external_ip
}
