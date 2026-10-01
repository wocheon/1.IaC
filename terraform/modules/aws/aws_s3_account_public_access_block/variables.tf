variable "aws_s3_apab_block_public_acls" {
  type        = bool
  description = "Whether to block public ACLs"
  default     = true
}

variable "aws_s3_apab_block_public_policy" {
  type        = bool
  description = "Whether to block public bucket policies"
  default     = true
}

variable "aws_s3_apab_ignore_public_acls" {
  type        = bool
  description = "Whether to ignore public ACLs"
  default     = true
}

variable "aws_s3_apab_restrict_public_buckets" {
  type        = bool
  description = "Whether to restrict public buckets"
  default     = true
}
