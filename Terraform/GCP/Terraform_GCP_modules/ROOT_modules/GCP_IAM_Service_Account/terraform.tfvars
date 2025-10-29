### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"

### GCP IAM Custom Role Configurations ###
role_id             = "terraform_test_customrole"
role_title          = "테라폼 테스트 커스텀 Role"
role_description    = "Terraform Custom Role"
#role_project_id     = "project_id"
role_permissions    = [
# 버킷 관련 권한
  "storage.buckets.create",
  "storage.buckets.delete",
  "storage.buckets.get",
  "storage.buckets.list",
  "storage.buckets.update",
  "storage.objects.create",
  "storage.objects.delete",
  "storage.objects.get",
  "storage.objects.list",
  
# VPC 네트워크 관련 권한  
  "compute.networks.create",
  "compute.networks.delete",
  "compute.networks.get",
  "compute.networks.list",
  "compute.networks.updatePolicy",
  
# 서브넷 관련 권한    
  "compute.subnetworks.create",
  "compute.subnetworks.delete",
  "compute.subnetworks.get",
  "compute.subnetworks.list",
  "compute.subnetworks.update",

# IAM SA 관련 권한 
  "iam.serviceAccounts.create",
  "iam.serviceAccounts.delete",
  "iam.serviceAccounts.get",
  "iam.serviceAccounts.list",
  "iam.serviceAccounts.update",
  
# IAM SA 키 관련 권한   
  "iam.serviceAccountKeys.create",
  "iam.serviceAccountKeys.delete",
  "iam.serviceAccountKeys.get",
  "iam.serviceAccountKeys.list",
  
# IAM 역할 관련 권한     
  "iam.roles.create",
  "iam.roles.delete",
  "iam.roles.get",
  "iam.roles.list",
  "iam.roles.update",
  
  "resourcemanager.projects.getIamPolicy",
  "resourcemanager.projects.setIamPolicy",

# GCP 방화벽 관련 권한
  "compute.firewalls.create",
  "compute.firewalls.delete",
  "compute.firewalls.get",
  "compute.firewalls.list",
  "compute.firewalls.update",
  
# Snapshot 관련 권한  
  "compute.snapshots.create",
  "compute.snapshots.delete",
  "compute.snapshots.get",
  "compute.snapshots.list",
  "compute.snapshots.useReadOnly",

# InstanceTemplate 관련 권한
  "compute.instanceTemplates.create",
  "compute.instanceTemplates.delete",
  "compute.instanceTemplates.get",
  "compute.instanceTemplates.list",
  
# Instance 관련 권한  
  "compute.instances.create",
  "compute.instances.delete",
  "compute.instances.get",
  "compute.instances.list",
  "compute.instances.start",
  "compute.instances.stop",
  
# Image 관련 권한    
  "compute.images.create",
  "compute.images.delete",
  "compute.images.get",
  "compute.images.list",
  
# Disk 관련 권한    
  "compute.disks.create",
  "compute.disks.delete",
  "compute.disks.get",
  "compute.disks.list",
  "compute.disks.use",
  "compute.disks.useReadOnly"
]

### GCP IAM Service_account Configurations ### 

new_service_account_id              = "terraform-custom-sa"
new_service_account_display_name    = "테라폼 테스트 커스텀 SA"
new_service_account_description     = "테라폼 테스트 커스텀 SA DESC"
#new_service_account_project_id     = "project_id"


