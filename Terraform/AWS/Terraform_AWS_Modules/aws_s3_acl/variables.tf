variable "aws_s3_bucket" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "aws_s3_acl" {
  type        = string
  description = "The canned ACL to apply to the bucket"
  default     = "private"  # 기본값은 private으로 설정
}
