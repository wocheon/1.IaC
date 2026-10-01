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

variable "control_plane_zone" {
  type    = string
  default = "asia-northeast3-a"
}

variable "gpu_worker_zone" {
  description = "N1 with T4 must be available in this zone."
  type        = string
  default     = "asia-northeast3-b"
}

variable "non_gpu_worker_zone" {
  type    = string
  default = "asia-northeast3-a"
}

variable "service_account" {
  type = string
}

variable "control_plane_vm_name" {
  type    = string
  default = "gcp-an3-a-gpu-cluster-control-plane"
}

variable "gpu_worker_vm_name" {
  description = "GPU worker name prefix. A sequence number is appended."
  type        = string
  default     = "gcp-an3-b-gpu-cluster-node"
}

variable "non_gpu_worker_vm_name" {
  description = "Non-GPU worker name prefix. A sequence number is appended."
  type        = string
  default     = "gcp-an3-a-gpu-cluster-cpu-node"
}

variable "control_plane_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "gpu_worker_machine_type" {
  type    = string
  default = "n1-standard-4"

  validation {
    condition     = startswith(var.gpu_worker_machine_type, "n1-")
    error_message = "gpu_worker_machine_type must use the N1 machine series."
  }
}

variable "non_gpu_worker_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "gpu_worker_count" {
  type    = number
  default = 2

  validation {
    condition     = var.gpu_worker_count >= 0 && floor(var.gpu_worker_count) == var.gpu_worker_count
    error_message = "gpu_worker_count must be a non-negative integer."
  }
}

variable "non_gpu_worker_count" {
  type    = number
  default = 0

  validation {
    condition     = var.non_gpu_worker_count >= 0 && floor(var.non_gpu_worker_count) == var.non_gpu_worker_count
    error_message = "non_gpu_worker_count must be a non-negative integer."
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

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "control_plane_internal_ip" {
  description = "Control-plane IP. Workers use the following addresses in the same /24."
  type        = string
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
  description = "Path to the SSH public key registered on every VM."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

locals {
  ubuntu_image   = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
  ssh_user       = var.ssh_user != null ? var.ssh_user : basename(pathexpand("~"))
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  ssh_metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "${local.ssh_user}:${local.ssh_public_key}"
  }
}

module "gce_control_plane" {
  source = "../gce-vm-cluster/modules/gce_instance"

  vm_name               = var.control_plane_vm_name
  machine_type          = var.control_plane_machine_type
  zone                  = var.control_plane_zone
  vm_status             = var.vm_status
  auto_restart          = var.auto_restart
  vm_labels             = merge(var.vm_labels, { role = "control-plane" })
  use_gpu_accelerator   = false
  gpu_type              = ""
  gpu_cnt               = 0
  boot_disk_image       = local.ubuntu_image
  boot_disk_snapshot    = null
  boot_disk_size        = var.boot_disk_size
  boot_disk_type        = var.boot_disk_type
  boot_disk_auto_delete = var.boot_disk_auto_delete
  boot_disk_labels      = var.boot_disk_labels

  enable_additional_disks = false
  additional_disks        = []

  network          = var.network
  subnetwork       = var.subnetwork
  internal_ip      = var.control_plane_internal_ip
  use_external_ip  = var.use_external_ip
  external_ip_tier = var.external_ip_tier
  network_tags     = var.network_tags

  service_account     = var.service_account
  service_scope       = "selected"
  service_scope_list  = var.service_scope_list
  default_scope_list  = var.service_scope_list
  on_host_maintenance = "MIGRATE"
  metadata            = local.ssh_metadata
}

module "gce_gpu_worker" {
  count = var.gpu_worker_count

  source = "../gce-vm-cluster/modules/gce_instance"

  vm_name               = "${var.gpu_worker_vm_name}${count.index + 1}"
  machine_type          = var.gpu_worker_machine_type
  zone                  = var.gpu_worker_zone
  vm_status             = var.vm_status
  auto_restart          = var.auto_restart
  vm_labels             = merge(var.vm_labels, { role = "gpu-worker" })
  use_gpu_accelerator   = true
  gpu_type              = "nvidia-tesla-t4"
  gpu_cnt               = 1
  boot_disk_image       = local.ubuntu_image
  boot_disk_snapshot    = null
  boot_disk_size        = var.boot_disk_size
  boot_disk_type        = var.boot_disk_type
  boot_disk_auto_delete = var.boot_disk_auto_delete
  boot_disk_labels      = var.boot_disk_labels

  enable_additional_disks = false
  additional_disks        = []

  network          = var.network
  subnetwork       = var.subnetwork
  internal_ip      = cidrhost("${var.control_plane_internal_ip}/24", tonumber(split(".", var.control_plane_internal_ip)[3]) + count.index + 1)
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

module "gce_non_gpu_worker" {
  count = var.non_gpu_worker_count

  source = "../gce-vm-cluster/modules/gce_instance"

  vm_name               = "${var.non_gpu_worker_vm_name}${count.index + 1}"
  machine_type          = var.non_gpu_worker_machine_type
  zone                  = var.non_gpu_worker_zone
  vm_status             = var.vm_status
  auto_restart          = var.auto_restart
  vm_labels             = merge(var.vm_labels, { role = "non-gpu-worker" })
  use_gpu_accelerator   = false
  gpu_type              = ""
  gpu_cnt               = 0
  boot_disk_image       = local.ubuntu_image
  boot_disk_snapshot    = null
  boot_disk_size        = var.boot_disk_size
  boot_disk_type        = var.boot_disk_type
  boot_disk_auto_delete = var.boot_disk_auto_delete
  boot_disk_labels      = var.boot_disk_labels

  enable_additional_disks = false
  additional_disks        = []

  network    = var.network
  subnetwork = var.subnetwork
  internal_ip = cidrhost(
    "${var.control_plane_internal_ip}/24",
    tonumber(split(".", var.control_plane_internal_ip)[3]) + var.gpu_worker_count + count.index + 1,
  )
  use_external_ip  = var.use_external_ip
  external_ip_tier = var.external_ip_tier
  network_tags     = var.network_tags

  service_account     = var.service_account
  service_scope       = "selected"
  service_scope_list  = var.service_scope_list
  default_scope_list  = var.service_scope_list
  on_host_maintenance = "MIGRATE"
  metadata            = local.ssh_metadata
}

output "instance_name" {
  value = concat(
    [module.gce_control_plane.instance_name],
    module.gce_gpu_worker[*].instance_name,
    module.gce_non_gpu_worker[*].instance_name,
  )
}

output "instance_zone" {
  value = concat(
    [module.gce_control_plane.instance_zone],
    module.gce_gpu_worker[*].instance_zone,
    module.gce_non_gpu_worker[*].instance_zone,
  )
}

output "internal_ip" {
  value = concat(
    [module.gce_control_plane.internal_ip],
    module.gce_gpu_worker[*].internal_ip,
    module.gce_non_gpu_worker[*].internal_ip,
  )
}

output "external_ip" {
  value = concat(
    [module.gce_control_plane.external_ip],
    module.gce_gpu_worker[*].external_ip,
    module.gce_non_gpu_worker[*].external_ip,
  )
}

output "gpu_workers" {
  value = [for worker in module.gce_gpu_worker : {
    name        = worker.instance_name
    zone        = worker.instance_zone
    internal_ip = worker.internal_ip
    external_ip = worker.external_ip
  }]
}

output "non_gpu_workers" {
  value = [for worker in module.gce_non_gpu_worker : {
    name        = worker.instance_name
    zone        = worker.instance_zone
    internal_ip = worker.internal_ip
    external_ip = worker.external_ip
  }]
}
