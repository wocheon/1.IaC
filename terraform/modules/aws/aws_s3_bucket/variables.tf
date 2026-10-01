variable "aws_s3_bucket" {
  type = string
}

variable "aws_s3_force_destroy" {
  type    = bool
  default = false
}

variable "aws_s3_object_lock_enabled" {
  type    = bool
  default = false
}

variable "aws_s3_tags" {
  type    = map(string)
  default = {}
}

