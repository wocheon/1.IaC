variable "aws_s3_bucket" {
  type = string
  description = "The name of the S3 bucket"
}

variable "aws_s3_index_document" {
  type        = string
  description = "Index document (e.g., index.html)"
}

variable "aws_s3_error_document" {
  type        = string
  description = "Error document (e.g., error.html)"
}

variable "aws_s3_redirect_routing_rules" {
  type = list(object({
    condition = object({
      key_prefix_equals = string
    })
    redirect = object({
      host_name = string
      protocol  = string
    })
  }))
  default = []
}
