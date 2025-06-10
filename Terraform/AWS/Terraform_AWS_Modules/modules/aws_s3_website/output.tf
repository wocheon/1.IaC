data "aws_region" "current" {}

output "website_endpoint" {
  value = "http://${var.aws_s3_bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}