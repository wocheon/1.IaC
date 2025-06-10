### AWS Region Configs ###

aws_region         = "ap-northeast-2"

### AWS EIP Configs ###

aws_eip_allocation_id        = ""
aws_eip_name                 = "test-eip"
aws_eip_domain               = "vpc"
#aws_eip_network_border_group = var.aws_eip_network_border_group
#aws_eip_public_ipv4_pool     = var.aws_eip_public_ipv4_pool
aws_eip_tags = {
    provider   = "terraform"
    user       = "ciw0707"
}

### AWS EC2 Configs ###

aws_ec2_ami                 = "ami-0f17cb072499f67d7"
aws_ec2_instance_type       = "t3.micro"
aws_ec2_key_name            = "cslee-ciw0707"
aws_ec2_subnet_id           = "subnet-0e3421ece9d178df5"
aws_ec2_security_group_ids  = ["sg-0fd445f3258c05d2c"]
aws_ec2_associate_public_ip = true
aws_ec2_root_volume_size    = 20
aws_ec2_root_volume_type    = "gp3"
aws_ec2_instance_name       = "terraform-ec2-test"

#aws_ec2_ebs_volumes = [
#  {
#    device_name = "/dev/xvdb"
#    volume_size = 50
#    volume_type = "gp3"
#  },
#  {
#    device_name = "/dev/xvdc"
#    volume_size = 100
#    volume_type = "gp3"
#  }
#]