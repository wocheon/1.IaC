resource "aws_s3_bucket_versioning" "this" {
  bucket = var.aws_s3_bucket

  versioning_configuration {
    status     = var.aws_s3_version_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.aws_s3_version_mfa_delete ? "Enabled" : "Disabled"
  }
}
