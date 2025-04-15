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

module "vpc_network" {
  source = "../modules/gcp_vpc_network"
  network_name             = var.vpc_network_name
  auto_create_subnetworks  = false
  routing_mode             = "REGIONAL"
}

module "subnetworks" {
  source = "../modules/gcp_subnetworks"
  network_self_link = module.vpc_network.network_self_link
  subnetworks       = var.subnetworks
}

module "firewall" {
  source = "../modules/gcp_firewall"
  network_self_link = module.vpc_network.network_self_link
  firewall_rules    = var.firewall_rules
}


output "vpc_network_name" {
  description = "The ID of the VPC network"
  value       = module.vpc_network.network_name
}

output "subnetworks" {
  description = "Subnetworks and their secondary IP ranges."
  value       = module.subnetworks.subnetworks
}

output "firewall" {
  description = "firewall_rules"
  value       = module.firewall.firewall_rule
}