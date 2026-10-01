resource "aws_instance" "ec2" {
  tags = {
    Name = var.aws_ec2_instance_name
  }

  ami                    = var.aws_ec2_ami
  instance_type          = var.aws_ec2_instance_type
  key_name               = var.aws_ec2_key_name
  subnet_id              = var.aws_ec2_subnet_id
  vpc_security_group_ids = var.aws_ec2_security_group_ids
  associate_public_ip_address = var.aws_ec2_associate_public_ip

  root_block_device {
    volume_size = var.aws_ec2_root_volume_size
    volume_type = var.aws_ec2_root_volume_type
  }

  dynamic "ebs_block_device" {
    for_each = var.aws_ec2_ebs_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
    }
  }

}
