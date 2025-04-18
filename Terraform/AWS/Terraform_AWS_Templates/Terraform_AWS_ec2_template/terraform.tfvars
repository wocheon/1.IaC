aws_region         = "ap-northeast-2"
ami                = "ami-xxxxx"
instance_type      = "t3.micro"
key_name           = "keyName"
subnet_id          = "subnet-xxxxxx"
security_group_ids = ["sg-xxxxx"]
associate_public_ip = true
root_volume_size   = 20
root_volume_type   = "gp3"
instance_name      = "terraform-ec2-test"

#ebs_volumes = [
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
#
