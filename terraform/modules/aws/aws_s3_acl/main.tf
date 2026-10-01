resource "aws_s3_bucket_acl" "this" {
  bucket = var.aws_s3_bucket
  acl    = var.aws_s3_acl
}
