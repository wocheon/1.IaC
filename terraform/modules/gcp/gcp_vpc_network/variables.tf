variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "Whether to create subnetworks automatically"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "REGIONAL"
}