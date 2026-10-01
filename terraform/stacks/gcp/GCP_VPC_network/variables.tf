variable "project" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

variable "vpc_network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnetworks" {
  description = "Subnetwork configurations"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_cidr_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
}

variable "firewall_rules" {
  description = "Firewall rule configurations"
  type = list(object({
    name          = string
    protocol      = string
    ports         = list(string)
    direction     = string
    priority      = number
    source_ranges = list(string)
    target_tags   = list(string)
  }))
}
