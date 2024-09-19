# Packer Configuration for Google Cloud Platform
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  default     = "gcp-in-ca"
}

variable "region" {
  description = "GCP Region"
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  default     = "asia-northeast3-a"
}

variable "image_name" {
  description = "The name of the image"
  default     = "packer-image-240911"
}

variable "network" {
  description = "Builder VMs Network"
  default     = "test-vpc-1"
}

variable "subnetwork" {
  description = "Builder VMs Subnetwork"
  default     = "test-vpc-sub-01"
}



source "googlecompute" "example" {
  credentials_file   = "service-account.json"
  project_id     = var.project_id
  zone         = var.zone
  source_image   = "ubuntu-2004-focal-v20240830"
  image_family   = "my-image-family"
  image_name     = var.image_name
  machine_type  = "e2-small"
  ssh_username    = "packer"
  image_storage_locations = [var.region]
  network    = var.network
  subnetwork = var.subnetwork
 
}

build {
  sources = ["source.googlecompute.example"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}

