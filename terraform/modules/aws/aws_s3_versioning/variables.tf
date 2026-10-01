variable "aws_s3_bucket" {
  type = string
  description = "The name of the S3 bucket"
}

variable "aws_s3_version_enabled" {
  type    = bool
  default = true
}

variable "aws_s3_version_mfa_delete" {
  type    = bool
  default = false
}
