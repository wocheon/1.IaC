output "snapshot_id" {
  description = "The ID of the created snapshot"
  value       = aws_ebs_snapshot.this.id
}
