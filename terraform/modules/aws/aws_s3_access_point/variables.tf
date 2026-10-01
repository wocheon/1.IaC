variable "aws_s3_access_point_name" {
  type        = string
  description = "The name of the S3 Access Point"
}

variable "aws_s3_bucket" {
  type        = string
  description = "The name of the S3 bucket associated with the Access Point"
}

variable "aws_s3_access_point_policy" {
  type        = string
  description = "The policy for the Access Point (JSON format)"
  default     = "{}"  # 기본적으로 빈 정책을 설정
}

variable "aws_s3_access_point_vpc_id" {
  type        = string
  description = "The VPC ID to associate the Access Point"
  default     = ""  # VPC ID가 없으면 빈 값
}

variable "aws_s3_access_point_tags" {
  type        = map(string)
  description = "Tags for the Access Point"
  default     = {}
}
