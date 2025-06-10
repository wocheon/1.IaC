resource "aws_s3_access_point" "this" {
  name       = var.aws_s3_access_point_name  
  bucket     = var.aws_s3_bucket  
  policy     = var.aws_s3_access_point_policy
  #vpc_id     = var.aws_s3_access_point_vpc_id
  #tags       = var.aws_s3_access_point_tags
}
