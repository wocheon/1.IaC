### AWS Region Configs ###

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

### AWS EIP Configs ###

variable "aws_eip_allocation_id" {
  description = "EC2 인스턴스의 AMI ID"
  type        = string
  default = null
}


variable "aws_eip_domain" {
  description = "Whether to allocate the address for use with instances in a VPC"
  type        = string
  default     = "vpc"
}

variable "aws_eip_name" {
  description = "Name tag for the EIP"
  type        = string
  default     = "my-eip"
}

variable "aws_eip_network_border_group" {
  description = "Set the location from which the EIP will be advertised"
  type        = string
  default     = null
}

variable "aws_eip_public_ipv4_pool" {
  description = "EC2 IPv4 address pool identifier or amazon"
  type        = string
  default     = null
}

variable "aws_eip_tags" {
  description = "Additional tags to associate with the EIP"
  type        = map(string)
  default     = {}
}

### AWS EC2 Configs ###

variable "aws_ec2_instance_name" {
  description = "EC2 인스턴스 이름"
  type        = string
}

variable "aws_ec2_ami" {
  description = "EC2 인스턴스의 AMI ID"
  type        = string
}

variable "aws_ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "aws_ec2_key_name" {
  description = "EC2 인스턴스에 접속할 SSH 키 이름"
  type        = string
}

variable "aws_ec2_subnet_id" {
  description = "EC2 인스턴스를 배치할 서브넷 ID"
  type        = string
}

variable "aws_ec2_security_group_ids" {
  description = "EC2 인스턴스에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "aws_ec2_associate_public_ip" {
  description = "퍼블릭 IP 할당 여부"
  type        = bool
}

variable "aws_ec2_root_volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
}

variable "aws_ec2_root_volume_type" {
  description = "루트 볼륨 타입 (gp2, gp3, io1 등)"
  type        = string
}

variable "aws_ec2_ebs_volumes" {
  description = "추가 EBS 볼륨 리스트"
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
  }))
  default = []
}