### AWS Region Configs ###

aws_region         = "ap-northeast-2"

### AWS EBS Configs ###
ebs_availability_zone = "ap-northeast-2a"
ebs_size              = 10
ebs_type              = "gp3"
#ebs_iops              = 3000
#ebs_throughput        = 125
ebs_encrypted         = false
ebs_source_snapshot   = "snap-0656b23e1a71e04d4"
ebs_tags = {
  Name = "example-ebs-volume"
}

### AWS EBS Snapshot Configs ###

#ebs_snapshot_volume_id               = "vol-0a1b2c3d4e5f6g7h8"
ebs_snapshot_description            = "Daily backup snapshot"
ebs_snapshot_storage_tier           = "standard"
ebs_snapshot_permanent_restore      = false
ebs_snapshot_temporary_restore_days = null

ebs_snapshot_tags = {
  Name        = "terrafrom-aws-snapshot-test"
  Environment = "dev"
}