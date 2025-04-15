variable "network_self_link" {
  description = "The self link of the VPC network"
  type        = string
}

variable "firewall_rules" {
  description = "List of firewall rules"
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
