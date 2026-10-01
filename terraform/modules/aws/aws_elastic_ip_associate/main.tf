resource "aws_eip_association" "this" {
  instance_id   = var.aws_eip_associate_instance_id
  allocation_id = var.aws_eip_associate_allocation_id
}