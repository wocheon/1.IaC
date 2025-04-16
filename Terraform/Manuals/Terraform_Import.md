
# Terraform import - GCP
  
## Terraform Import 란 ? 
- Terraform import를 통해 기존 수동으로 생성한 리소스를 Terrafrom State에 가져올 수 있음 
    - 이미 존재하는 리소스를 IaC 코드로 관리할 수 있도록 해주는 기능 
    
- Import 된 리소스는 변경사항을 Apply 할수 있으며, `Destroy로 삭제가능`
    - Import 해제가 필요하면 tfstate를 삭제하여 해제

### Terraform Import  사용 방법 

1. Terrafrom import를 위한 main.tf 작성 
    - terraform 과 provider 구문은 생략 가능
```json
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "google" {
  project = "gcp-in-ca"
  region  = "asia-northeast3-a"
}

resource "google_compute_engine" "example" {
}
```

2. Terraform Import로 기존 리소스를 terraform.tfstate에 저장 

```sh
# Import전 Terraform init 필요
$ terraform init

# 기본 형식 : terraform import [리소스 타입].[리소스명]
$ terraform import google_compute_instance.example projects/gcp-in-ca/zones/asia-northeast3-a/instances/db1
```

3. Import 된 리소스의 tfstate를 HCL 형식으로 표기 
    - 해당 내용을 통해 tf 파일을 구성 후, 리소스 변경 가능 
```bash
# terraform state list 확인 
$ terraform state list 
google_compute_engine.example

# 현재 terraform 리소스의 state를 출력 
$ terrafom show # 전체리소스 출력 (리소스가 여러 개인 경우, 전부 출력)
    or
$ terraform state show google_compute_engine.example
resource "google_compute_instance" "my_vm" {
  id                            = "projects/my-proj/zones/asia-northeast3-a/instances/my-instance"
  name                          = "my-instance"
  machine_type                  = "e2-medium"
  zone                          = "asia-northeast3-a"
  can_ip_forward                = false
  tags                          = []
  ...
  boot_disk {
    auto_delete                 = true
    device_name                 = "my-instance"
    ...
  }

  network_interface {
    network                     = "default"
    access_config {
      nat_ip                    = "34.x.x.x"
    }
  }
}
```

### 참고. Terraform Import 해제 
- 더 이상 Terraform 을 통해 리소스를 제어할 필요가 없으면 tfstate 파일을 삭제하여 import 해제 가능

## Improt 된 리소스의 Plan/Apply/Destory

### 테스트 용 디스크 생성 

- 테스트용 디스크 생성 
    - 디스크 명 : gce-terraform-disk-test
    - SIZE : 30GB
    - 유형 : pd-standard
    - 영역 : asia-northeast3-a 
    - 라벨 : 
        - type : gce-boot-disk
        - user : wocheon07
    

- 테스트용 디스크 Import 용 main.tf 작성
> main.tf
```json
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "google" {
  project = "gcp-in-ca"
  region  = "asia-northeast3-a"
}

resource "google_compute_disk" "test_disk" {
}
```

#### 테스트 용 디스크 Terraform Import 

- 테스트용 디스크 Import 

```sh
$ terraform init 

$ terraform import google_compute_disk.test_disk projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test

google_compute_disk.test_disk: Importing from ID "projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test"...
google_compute_disk.test_disk: Import prepared!
  Prepared google_compute_disk for import
google_compute_disk.test_disk: Refreshing state... [id=projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test]

Import successful!
```

#### 테스트 용 디스크의 main.tf 작성

```sh 
# terraform show 결과를 tf파일로 저장 
# 색상 코드로 인해 null 부분이 깨지므로 출력결과를 복사하여 파일로 저장
$ terraform show 
```

- terraform show 출력값을 수정하여 main.tf의 resource를 대체
    - 해당 리소스에서 수정이 불가한 항목을 제외 
        - EX) creation_timestamp, disk_id, id, label_fingerprint, self_link
        - 해당 Terraform 리소스의 공식 문서 참고하여 수정

> main.tf
```json
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.29.0"
    }
  }
}

provider "google" {
  project = "gcp-in-ca"
  region  = "asia-northeast3-a"
}

resource "google_compute_disk" "test_disk" {
    access_mode                    = null
    create_snapshot_before_destroy = false
    description                    = null
    enable_confidential_compute    = false
    image                          = null
    labels                         = {
    "type"               = "gce-boot-disk"
    "user"               = "wocheon07"    
    }
    last_attach_timestamp          = null
    last_detach_timestamp          = null
    licenses                       = []
    name                           = "gce-terraform-disk-test"
    physical_block_size_bytes      = 4096
    project                        = "gcp-in-ca"
    provisioned_iops               = 0
    provisioned_throughput         = 0
    size                           = 30
    snapshot                       = null
    source_disk                    = null
    source_disk_id                 = null
    source_image_id                = null
    source_instant_snapshot        = null
    source_instant_snapshot_id     = null
    source_snapshot_id             = null
    storage_pool                   = null
    type                           = "pd-standard"
    zone                           = "asia-northeast3-a"
}
```


- main.tf 리소스내 label 추가 및 디스크 사이즈를 변경
> main.tf
```json
...

resource "google_compute_disk" "test_disk" {
...
labels                         = {
"type"               = "gce-boot-disk"
"user"               = "wocheon07"
"terraform_imported" = "true"
}
...
size                           = 40
}
```

#### 테스트 용 디스크 Plan/Apply


- plan으로 변경사항 확인 후 Apply

``` sh
$ terraform plan 

  # google_compute_disk.test_disk will be updated in-place
  ~ resource "google_compute_disk" "test_disk" {
        id                             = "projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test"
      ~ labels                         = {
          + "terraform_imported" = "true"
        }
        name                           = "gce-terraform-disk-test"
      ~ size                           = 30 -> 40
      ~ terraform_labels               = {
          + "terraform_imported" = "true"
        }
        # (28 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.


$ terraform apply --auto-approve 

oogle_compute_disk.test_disk: Modifying... [id=projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test]
google_compute_disk.test_disk: Still modifying... [id=projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test, 10s elapsed]
google_compute_disk.test_disk: Modifications complete after 11s [id=projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```


#### 테스트 용 디스크 Destroy
- terraform destroy 수행하여 해당 리소스 삭제
```sh
$ terraform destroy --auto-approve

google_compute_disk.test_disk: Destroying... [id=projects/gcp-in-ca/zones/asia-northeast3-a/disks/gce-terraform-disk-test]
google_compute_disk.test_disk: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.

# Destory 후 실제 리소스 삭제 확인 
$ gcloud compute disks list | grep gce-terraform-disk-test
```

