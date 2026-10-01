resource "aws_s3_account_public_access_block" "this" {
  block_public_acls            = var.aws_s3_apab_block_public_acls
  block_public_policy          = var.aws_s3_apab_block_public_policy
  ignore_public_acls           = var.aws_s3_apab_ignore_public_acls
  restrict_public_buckets      = var.aws_s3_apab_restrict_public_buckets
}
