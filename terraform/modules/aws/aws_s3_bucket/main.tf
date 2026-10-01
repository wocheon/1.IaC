resource "aws_s3_bucket" "this" {
  bucket              = var.aws_s3_bucket  
  force_destroy       = var.aws_s3_force_destroy
  object_lock_enabled = var.aws_s3_object_lock_enabled
  tags                = var.aws_s3_tags
}