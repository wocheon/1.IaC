output "versioning_status" {
  value = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}
