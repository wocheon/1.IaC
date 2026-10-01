# Terraform GCP 모듈 메뉴얼

## GCP 모듈 기본 구조
```
├── 리소스 별 Root 모듈
│   ├── main.tf
│   ├── terraform_command.sh
│   ├── terraform.tfvars
│   └── variables.tf
└── modules
│   ├── 모듈 #1
│   │   ├── main.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   └── 모듈 #2
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
    - root 모듈에서 재사용 가능한 하위 모듈들
    - 각 파일 용도
        - `main.tf` : 모듈 안에서 실제 리소스를 생성하거나 구성하는 파일
        - `variables.tf` : 모듈이 외부로부터 받아야 할 입력 변수들을 정의
        - `output.tf` : 모듈이 생성한 리소스의 값 을 출력시에 사용 
            - 출력한 값은 Root 모듈이나 다른 모듈에서 참고 가능



## 모듈 구성 예시

###  Root 모듈 예시 
```hcl
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
```hcl
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