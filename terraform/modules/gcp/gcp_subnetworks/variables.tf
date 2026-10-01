variable "network_self_link" {
  description = "The self link of the VPC network"
  type        = string
}

variable "subnetworks" {
  description = "Subnetwork configurations"
  type = list(object({
    name             = string
    ip_cidr_range    = string
    region           = string
    secondary_ip_cidr_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
}
