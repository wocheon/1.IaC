variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "ami" {
  description = "EC2 인스턴스의 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "key_name" {
  description = "EC2 인스턴스에 접속할 SSH 키 이름"
  type        = string
}

variable "subnet_id" {
  description = "EC2 인스턴스를 배치할 서브넷 ID"
  type        = string
}

variable "security_group_ids" {
  description = "EC2 인스턴스에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "associate_public_ip" {
  description = "퍼블릭 IP 할당 여부"
  type        = bool
}

variable "root_volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
}

variable "root_volume_type" {
  description = "루트 볼륨 타입 (gp2, gp3, io1 등)"
  type        = string
}

variable "ebs_volumes" {
  description = "추가 EBS 볼륨 리스트"
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
  }))
  default = []
}

variable "instance_name" {
  description = "EC2 인스턴스 이름"
  type        = string
}