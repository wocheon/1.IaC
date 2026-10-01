resource "aws_ebs_volume" "this" {
  availability_zone = var.ebs_availability_zone
  size              = var.ebs_size
  type              = var.ebs_type
  iops              = var.ebs_iops
  throughput        = var.ebs_throughput
  encrypted         = var.ebs_encrypted
  kms_key_id        = var.ebs_kms_key_id
  tags              = var.ebs_tags
  snapshot_id       = var.ebs_source_snapshot
}
