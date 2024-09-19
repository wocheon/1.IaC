# Packer Configuration for Google Cloud Platform
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
    ansible = {
      source = "github.com/hashicorp/ansible"
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
#  ssh_username    = "packer"
  ssh_username    = "root"
  image_storage_locations = [var.region]
  network    = var.network
  subnetwork = var.subnetwork
 
}

build {
  sources = ["source.googlecompute.example"]

  provisioner "shell" {
    inline = [
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsqnZAQKBtydbn040mWetqauZ6Kx+a7r5B4AH4gv2iPmRpSJdBsphKioxaeQ0F9+h5DMY5xfEQIW2PXc7UM9+we2OHf0pirgA1QTXPOoXBmd31Z1dMWMlIBIpXjoyLZ79XHRk9r0U7hoO9/zAUrG49csq+bfRPYZG8GtQcXnRa7mVeapTxIHeHmoiEXTOMx4qG/8iR/BfWjLn55RXXwHDHgq4pm+3NBCiZzV+EgMKLppP2tM4x6Dq8WZT5yxbTGjSypfYULiLB5dPLx2t3KuiCnQBRephhb9pzcrxQAeh7AHI5EmRs8o5W6bCK6iwTPmnRHqeIvWc9Xo2gJLqYXSZd root@gcp-ansible-test' >> /root/.ssh/authorized_keys"
    ]
  }

  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_1.yaml"
  
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"    
  ]
  }

  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_2.yaml"
  
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"    
  ]
  }

  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_3.yaml"
  
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"    
  ]
  }
}

