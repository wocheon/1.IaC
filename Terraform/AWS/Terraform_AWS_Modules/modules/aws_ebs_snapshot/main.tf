resource "aws_ebs_snapshot" "this" {
  volume_id               = var.ebs_snapshot_volume_id
  description             = var.ebs_snapshot_description
  storage_tier            = var.ebs_snapshot_storage_tier
  permanent_restore       = var.ebs_snapshot_permanent_restore
  temporary_restore_days  = var.ebs_snapshot_temporary_restore_days
  tags                    = var.ebs_snapshot_tags
  timeouts {
    create = "30m"  # 30분 동안 기다리도록 설정
  }
}
