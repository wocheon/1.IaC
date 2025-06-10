### AWS Region Configs ###

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

### AWS EBS Configs ###
variable "ebs_availability_zone" {
  description = "The AZ where the EBS volume will be created"
  type        = string
}

variable "ebs_size" {
  description = "The size of the drive in GiBs"
  type        = number
}

variable "ebs_type" {
  description = "The type of EBS volume"
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "The amount of provisioned IOPS"
  type        = number
  default     = null
}

variable "ebs_throughput" {
  description = "The throughput to provision in MiB/s (only for gp3)"
  type        = number
  default     = null
}

variable "ebs_encrypted" {
  description = "Whether the volume should be encrypted"
  type        = bool
  default     = true
}

variable "ebs_kms_key_id" {
  description = "The full ARN of the KMS key to use when encrypting the volume"
  type        = string
  default     = null
}

variable "ebs_source_snapshot" {
  description = "The Source Snapshot ID of volume"
  type        = string
  default     = null
}

variable "ebs_tags" {
  description = "Tags to assign to the volume"
  type        = map(string)
  default     = {}
}
