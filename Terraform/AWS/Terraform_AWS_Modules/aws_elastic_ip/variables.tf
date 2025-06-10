variable "aws_eip_domain" {
  description = "Whether to allocate the address for use with instances in a VPC"
  type        = string
  default     = "vpc"
}

variable "aws_eip_name" {
  description = "Name tag for the EIP"
  type        = string
  default     = "my-eip"
}

variable "aws_eip_network_border_group" {
  description = "Set the location from which the EIP will be advertised"
  type        = string
  default     = null
}

variable "aws_eip_public_ipv4_pool" {
  description = "EC2 IPv4 address pool identifier or amazon"
  type        = string
  default     = null
}

variable "aws_eip_tags" {
  description = "Additional tags to associate with the EIP"
  type        = map(string)
  default     = {}
}
