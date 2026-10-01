terraform {
  # Terraform Cloud Workspace
  cloud { 
    organization = "terraform_cloud_wocheon" 
    workspaces { 
      name = "terraform-cloud-workspace-aws-repo" 
    } 
  } 
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# 조건부 EIP 생성
module "eip" {
  source  = "app.terraform.io/terraform_cloud_wocheon/aws-module-registry/aws//modules/aws_elastic_ip"
  version = "1.0.2"
  count  = var.aws_eip_allocation_id == "" || var.aws_eip_allocation_id == null  ? 1 : 0
  aws_eip_name                 = var.aws_eip_name
  aws_eip_domain               = var.aws_eip_domain
  aws_eip_network_border_group = var.aws_region
  aws_eip_public_ipv4_pool     = var.aws_eip_public_ipv4_pool
  aws_eip_tags                 = var.aws_eip_tags
}

# EC2 인스턴스 생성
module "ec2_instance" {
  source  = "app.terraform.io/terraform_cloud_wocheon/aws-module-registry/aws//modules/aws_ec2"  
  version = "1.0.2"
  aws_ec2_instance_name      	  = var.aws_ec2_instance_name  
  aws_ec2_ami           	      = var.aws_ec2_ami
  aws_ec2_instance_type 	      = var.aws_ec2_instance_type
  aws_ec2_key_name      	      = var.aws_ec2_key_name
  aws_ec2_subnet_id     	      = var.aws_ec2_subnet_id
  aws_ec2_security_group_ids 	  = var.aws_ec2_security_group_ids
  aws_ec2_associate_public_ip 	= var.aws_ec2_associate_public_ip
  aws_ec2_root_volume_size   	  = var.aws_ec2_root_volume_size
  aws_ec2_root_volume_type   	  = var.aws_ec2_root_volume_type
}


module "eip_associate" {  
  source  = "app.terraform.io/terraform_cloud_wocheon/aws-module-registry/aws//modules/aws_elastic_ip_associate"  
  version = "1.0.2"  
  aws_eip_associate_instance_id = module.ec2_instance.instance_id
  aws_eip_associate_allocation_id = var.aws_eip_allocation_id == "" || var.aws_eip_allocation_id == null ? module.eip[0].allocation_id : var.aws_eip_allocation_id 
}