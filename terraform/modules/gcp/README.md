# Terraform GCP 모듈 메뉴얼

## GCP 모듈 기본 구조
```
├── 리소스 별 Root 모듈
│   ├── main.tf
│   ├── terraform_command.sh
│   ├── terraform.tfvars
│   └── variables.tf
└── modules
│   ├── GCP 모듈 #1
│   │   ├── main.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   └── GCP 모듈 #2
│       ├── main.tf
│       ├── output.tf
│       └── variables.tf
├── README.md
└── tfstate_delete.sh
```

- 리소스 별 Root 모듈
    - Terraform을 실행하는 entry point 역할
    - 각 파일 용도
        - `main.tf` :  modules 안에 정의된 하위 모듈들을 호출
        - `varialbes.tf` : Root 모듈에서 사용하는 변수들을 정의하는 파일
        - `terraform.tfvars` : variables.tf에서 정의한 변수들에 대해 실제 값을 할당하는 파일
        - `terraform_command.sh` : terraform 커맨드 실행시 --var_file 옵션을 자동할당하여 사용할 수 있는 스크립트             
            - plan/apply/destroy 시 사용 가능
            - `terraform init` 별도 실행 필요

- modules 디렉터리
    - root 모듈에서 재사용 가능한 GCP 하위 모듈들
    - 각 파일 용도
        - `main.tf` : 모듈 안에서 실제 리소스를 생성하거나 구성하는 파일
        - `variables.tf` : 모듈이 외부로부터 받아야 할 입력 변수들을 정의
        - `output.tf` : 모듈이 생성한 리소스의 값 을 출력시에 사용 
            - 출력한 값은 Root 모듈이나 다른 모듈에서 참고 가능



## 모듈 구성 예시

###  Root 모듈 예시 
```json
# Provider는 Root 모듈에만 포함
provider "google" {
  project = var.project
  region  = var.region
}

# 하위 모듈을 불러와 사용 
module "gce_disk" {
  source = "../modules/gce_disk"
  new_disk_name         = var.new_disk_name
  new_disk_zone         = var.new_disk_zone
  new_disk_type         = var.new_disk_type
  new_disk_size         = var.new_disk_size
  new_disk_labels       = var.new_disk_labels
### Source Configurations ###
  new_disk_image_id              = var.new_disk_image_id
  new_disk_snapshot_id           = var.new_disk_snapshot_id  
}

# apply 후 결과값을 Output으로 확인 
# 모듈 참조시 output.tf에 정의된 값만 사용가능
output "gce_disk_id" {
  description = "Show GCE disk ID"
  value       = module.gce_disk.disk_id
}

output "gce_disk_self_link" {
  description = "Show GCE disk ID"
  value       = module.gce_disk.self_link
}
```

### 하위 GCP 모듈 예시
```json
resource "google_compute_disk" "gce_disk" {
        name            = var.new_disk_name
        zone            = var.new_disk_zone
        type            = var.new_disk_type
        size            = var.new_disk_size
        labels          = var.new_disk_labels
        image = var.new_disk_image_id != null ? var.new_disk_image_id : null
        snapshot = var.new_disk_snapshot_id != null && var.new_disk_image_id == null ? var.new_disk_snapshot_id : null
}
```

### 모듈 구성 시 주의 사항 
- 특정 모듈 사용시 모듈 내 variables로 정의된 모든 변수 정의 필요 (기본값 존재시 생략가능)
    - 모듈내 variables.tf 를 기반으로 Root 모듈의 variables.tf를 구성하는 것이 좋음

- Root 모듈에서 모듈에 대한 Output 사용시 해당 모듈의 ouptut.tf에 정의된 값만 사용가능 
    - 해당 output.tf 값은 리소스의 Attributes Reference를 참조하여 작성

## Terraform 사용시  GCP Service Account 권한 설정 

### 전체 모듈 사용시 필요 권한

- 현재 모듈 목록
```
├── gce_disk
├── gce_image
├── gce_instance
├── gce_instance_template
├── gce_snapshot
├── gcp_firewall
├── gcp_iam_role
├── gcp_iam_role_binding
├── gcp_iam_service_account
├── gcp_iam_service_account_key
├── gcp_subnetworks
├── gcp_vpc_network
└── gcs_storage_bucket
```

- 필요 권한 목록

```json
[
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
```

- 별도 커스텀 역할 생성 후 부여 혹은 다음 역할 부여 필요 
    - 서비스 계정 관리자
    - 서비스 계정 키 관리자
    - 역할 관리자
    - 저장소 관리자
    - 프로젝트 IAM 관리자
    - Compute 인스턴스 관리자(v1)
    - Kubernetes Engine 서비스 에이전트


## GCE_IAM_Service_Account (서비스 계정 생성 루트 모듈) 사용시 주의 사항 

### 현재 gcloud로그인 계정의 IAM 역할 확인 필요

- Terraform 실행 GCP 서비스 계정 확인 방법
    - 현재 gcloud 로그인 계정 확인 
    ```
    gcloud config configurations list
    ```


- **Terraform을 실행하는 계정** 이 아래 권한을 가지고 있는지 확인 필요

   | 역할 | 설명 |
   |:------|:-----|
   | `roles/resourcemanager.projectIamAdmin` | 프로젝트의 IAM 권한 수정 가능 |
   | `roles/iam.roleAdmin` | 사용자 정의 역할(Role) 관리 가능 |
   | `roles/iam.serviceAccountAdmin` | 서비스 계정 관리 가능 |
   | `roles/iam.serviceAccountKeyAdmin` | 서비스 계정 키 관리 가능 (키 파일 만들 때 필요) |

- 현재 서비스 계정에 해당 권한이 부여되지않은 경우, apply 시 오류 발생 