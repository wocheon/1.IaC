# Terraform GCP

## 개요 
- Terraform을 통해 GCP 리소스를 생성, 변경, 삭제를 구현
- Terraform으로 여러 리소스를 한번에 생성 
- 재사용 가능한 템플릿 형태로 tf파일 구성

## Terraform 설치 
```bash
 $ wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip

$ unzip terraform_1.5.7_linux_amd64.zip

$ mv terraform /usr/local/bin/

$ terraform -v
Terraform v1.5.7
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.9.5. You can update by downloading from https://www.terraform.io/downloads.html
 ```

## Terraform - GCP 연동  
- google-cloud-cli 를 통해 연동되므로 현재 gcloud 설정을 확인 
- PROJECT 및 기본 리전 등을 지정필요 (gcloud init)

```sh
$ gcloud init 

$ gcloud config configurations list 

NAME     IS_ACTIVE  ACCOUNT                                             PROJECT    COMPUTE_DEFAULT_ZONE  COMPUTE_DEFAULT_REGION
default  True       487401709675-compute@developer.gserviceaccount.com  gcp-in-ca  asia-northeast3-c     asia-northeast3
```


## Terraform 주요 명령어
|명령어|기능|용도|
|:-:|:-|:-|
|terraform init| - 사용 중인 Terraform 설정 파일에 지정된 프로바이더를 설치 <br> - 필요한 모듈을 다운로드| Terraform 작업 디렉토리를 처음 설정 혹은 새로운 프로바이더나 모듈을 추가하거나 변경했을 때 실행|
|terraform plan|- 현재의 인프라 상태와 Terraform 설정 파일의 차이를 분석하여 어떤 변경이 필요한지 확인 <br> - 실제 리소스를 변경하지 않고, 계획만 수립|terraform apply를 실행하기 전에 어떤 변경이 이루어질지 확인하고 싶을 때 사용
|terraform apply| - terraform plan에서 수립한 계획을 실행하여 실제 리소스를 프로비저닝하거나 업데이트 <br> - 실행 전 사용자에게 확인 요청( -auto-approve 옵션 사용시 확인없이 자동 적용)| 인프라 배포/업데이트 시 사용|
|terraform destroy|- 현재 상태 파일을 기반으로 모든 리소스를 삭제 (-auto-approve 가능)|모든 인프라를 정리 혹은 리소스 초기화 시 사용|
|terraform show|- 현재 Terraform 상태 파일 또는 계획 파일의 내용을 출력|인프라의 현재 상태를 확인하거나, 계획 파일을 검토할 때 사용|
|terraform output|- Terraform 설정 파일에서 정의한 출력 값(output value)을 표시 <br> - 다른 도구나 스크립트에서 활용할 수 있도록 결과를 텍스트나 JSON 형태로 출력|배포된 리소스의 정보 확인 혹은 다른 프로세스에서 사용 시|
|terraform validate|- tf 파일 문법 및 유효성 검사|작성한 tf파일의 문법검사 용도|
|terraform fmt|- Terraform 설정 파일의 형식을 정리<br>- 설정 파일을 표준 형식으로 자동 정리하여 일관성을 유지|코드의 가독성 향상을 위한 목적|
|terraform taint|- 특정 리소스를 '오염된(tainted)' 상태로 표시하여 다음 terraform apply 실행 시 해당 리소스를 강제로 다시 생성|리소스의 문제가 발생했을 때 또는 해당 리소스를 다시 생성하고자 할 때 사용|
|terraform import|- 기존 인프라 리소스를 Terraform 상태로 가져오는 명령어| 기존 리소스를 Terraform 관리 하에 편입시킬 때 사용|


## Terraform import로 GCP VM 정보 가져오기
- Terraform import 명령어를 통해 VM의 정보를 가져와 Terrafrom 리소스에 포함 시킬 수 있음.
    - VM외의 다른 리소스도 가능함

- Import 시 terraform.tfstate 파일에 VM 정보가 기록됨

- AWS의 경우 tfstate 파일을 .tf파일로 전환해주는 기능이 있으나, GCP에서는 tf파일을 직접 작성해줘야함 


### Terrafrom import - main.tf 작성 
```
resource "google_compute_engine" "example" {
}
```

### Terraform imort - VM import 
- terraform - GCP 간 연동이 완료되어야 정상 작동
```
$ terraform init

$ terraform import google_compute_instance.example projects/gcp-in-ca/zones/asia-northeast3-a/instances/db1
```


## Terraform - GCP 리소스 샘플  tf 파일 모음 
- 공식 Github 
    - https://github.com/terraform-google-modules/terraform-docs-samples.git

```
git clone https://github.com/terraform-google-modules/terraform-docs-samples.git --single-branch .
```


## Terraform으로 VM 생성 / 변경 / 삭제 

### VM 생성 

- GCP VM 생성을 위한 main.tf 파일 작성

> main.tf

```ruby
resource "google_compute_instance" "default" {
  project = "gcp-in-ca"
  name         = "terraform-test-vm"
  machine_type = "e2-micro"
  zone         = "asia-northeast3-c"
  desired_status = "RUNNING" # 생성시에는 RUNNING만 사용 가능

  boot_disk {
    initialize_params {
      image = "centos-mariadb-image"
    }
  }
  network_interface {
    network = "test-vpc-1"
    subnetwork = "test-vpc-sub-01"
    subnetwork_project = "gcp-in-ca"
    network_ip = "192.168.1.104"
    access_config {
    }
  }
}
```

- Terraform plan 명령어를 통해 현재 설정을 다시 확인

```ruby
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_instance.default will be created
  + resource "google_compute_instance" "default" {
      + can_ip_forward       = false
      + cpu_platform         = (known after apply)
      + current_status       = (known after apply)
      + deletion_protection  = false
      + desired_status       = "RUNNING"
      + effective_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + id                   = (known after apply)
      + instance_id          = (known after apply)
      + label_fingerprint    = (known after apply)
      + machine_type         = "e2-micro"
      + metadata_fingerprint = (known after apply)
      + min_cpu_platform     = (known after apply)
      + name                 = "terraform-test-vm"
      + project              = "gcp-in-ca"
      + self_link            = (known after apply)
      + tags_fingerprint     = (known after apply)
      + terraform_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + zone                 = "asia-northeast3-c"

      + boot_disk {
          + auto_delete                = true
          + device_name                = (known after apply)
          + disk_encryption_key_sha256 = (known after apply)
          + kms_key_self_link          = (known after apply)
          + mode                       = "READ_WRITE"
          + source                     = (known after apply)

          + initialize_params {
              + image                  = "centos-mariadb-image"
              + labels                 = (known after apply)
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + size                   = (known after apply)
              + type                   = (known after apply)
            }
        }

      + network_interface {
          + internal_ipv6_prefix_length = (known after apply)
          + ipv6_access_type            = (known after apply)
          + ipv6_address                = (known after apply)
          + name                        = (known after apply)
          + network                     = "test-vpc-1"
          + network_ip                  = "192.168.1.104"
          + stack_type                  = (known after apply)
          + subnetwork                  = "test-vpc-sub-01"
          + subnetwork_project          = "gcp-in-ca"

          + access_config {
              + nat_ip       = (known after apply)
              + network_tier = (known after apply)
            }
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

- Terraform apply 명령어로 VM 생성 
```sh
$ terraform apply --auto-approve # 확인 없이 바로 실행하기

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_instance.default will be created
  + resource "google_compute_instance" "default" {
      + can_ip_forward       = false
      + cpu_platform         = (known after apply)
      + current_status       = (known after apply)
      + deletion_protection  = false
      + desired_status       = "RUNNING"
      + effective_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + id                   = (known after apply)
      + instance_id          = (known after apply)
      + label_fingerprint    = (known after apply)
      + machine_type         = "e2-micro"
      + metadata_fingerprint = (known after apply)
      + min_cpu_platform     = (known after apply)
      + name                 = "terraform-test-vm"
      + project              = "gcp-in-ca"
      + self_link            = (known after apply)
      + tags_fingerprint     = (known after apply)
      + terraform_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + zone                 = "asia-northeast3-c"

      + boot_disk {
          + auto_delete                = true
          + device_name                = (known after apply)
          + disk_encryption_key_sha256 = (known after apply)
          + kms_key_self_link          = (known after apply)
          + mode                       = "READ_WRITE"
          + source                     = (known after apply)

          + initialize_params {
              + image                  = "centos-mariadb-image"
              + labels                 = (known after apply)
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + size                   = (known after apply)
              + type                   = (known after apply)
            }
        }

      + network_interface {
          + internal_ipv6_prefix_length = (known after apply)
          + ipv6_access_type            = (known after apply)
          + ipv6_address                = (known after apply)
          + name                        = (known after apply)
          + network                     = "test-vpc-1"
          + network_ip                  = "192.168.1.104"
          + stack_type                  = (known after apply)
          + subnetwork                  = "test-vpc-sub-01"
          + subnetwork_project          = "gcp-in-ca"

          + access_config {
              + nat_ip       = (known after apply)
              + network_tier = (known after apply)
            }
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
google_compute_instance.default: Creating...
google_compute_instance.default: Still creating... [10s elapsed]
google_compute_instance.default: Still creating... [20s elapsed]
google_compute_instance.default: Creation complete after 28s [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

### VM 변경
- VM 정보를 변경하는 경우 다음 방식을 통해 진행
    - 변경하려는 정보가 현재 상태에서 적용 가능한경우 
        - 그대로 정보만 변경하여 반영됨

    - 변경하려는 정보가 현재 상태에 적용 불가한 경우 ex) 내부 IP 변경 , VM명 등 
        - 기존 VM 삭제 후 재생성 수행

    - 변경 사항이 없는 경우 
        - 변동없이 유지


- 현재 상태(RUNNING)에서 변경 가능한 경우 
    - 외부 IP 제거

```sh
$ terraform plan
...

  # google_compute_instance.default will be updated in-place
  ~ resource "google_compute_instance" "default" {
        id                   = "projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm"
        name                 = "terraform-test-vm"
        tags                 = []
        # (19 unchanged attributes hidden)

      ~ network_interface {
            name                        = "nic0"
            # (7 unchanged attributes hidden)

          - access_config {
              - nat_ip       = "34.64.194.165" -> null
              - network_tier = "PREMIUM" -> null
            }
        }

        # (3 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```


- 변경하려는 정보가 현재 상태에 적용 불가한 경우 
    - 내부 IP 변경
```sh
$ terraform plan
...
      ~ network_interface {
          ~ internal_ipv6_prefix_length = 0 -> (known after apply)
          + ipv6_access_type            = (known after apply)
          + ipv6_address                = (known after apply)
          ~ name                        = "nic0" -> (known after apply)
          ~ network                     = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/global/networks/test-vpc-1" -> "test-vpc-1"
          ~ network_ip                  = "192.168.1.104" -> "192.168.1.102" # forces replacement
          - queue_count                 = 0 -> null
          ~ stack_type                  = "IPV4_ONLY" -> (known after apply)
          ~ subnetwork                  = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/regions/asia-northeast3/subnetworks/test-vpc-sub-01" -> "test-vpc-sub-01"
            # (1 unchanged attribute hidden)
...

Plan: 1 to add, 0 to change, 1 to destroy.

```



- 변경사항 없는 경우 

```sh
$ terraform plan
google_compute_instance.default: Refreshing state... [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```


### VM 삭제
- terraform destroy를 통해 main.tf파일에 등록된 리소스를 삭제
```ruby
terraform destroy
google_compute_instance.default: Refreshing state... [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # google_compute_instance.default will be destroyed
  - resource "google_compute_instance" "default" {
      - can_ip_forward       = false -> null
      - cpu_platform         = "Intel Broadwell" -> null
      - current_status       = "RUNNING" -> null
      - deletion_protection  = false -> null
      - desired_status       = "RUNNING" -> null
      - effective_labels     = {
          - "goog-terraform-provisioned" = "true"
        } -> null
      - enable_display       = false -> null
      - id                   = "projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm" -> null
      - instance_id          = "449769163015383762" -> null
      - label_fingerprint    = "vezUS-42LLM=" -> null
      - labels               = {} -> null
      - machine_type         = "e2-micro" -> null
      - metadata             = {} -> null
      - metadata_fingerprint = "uT2yNdowjAI=" -> null
      - name                 = "terraform-test-vm" -> null
      - project              = "gcp-in-ca" -> null
      - resource_policies    = [] -> null
      - self_link            = "https://www.googleapis.com/compute/v1/projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm" -> null
      - tags                 = [] -> null
      - tags_fingerprint     = "42WmSpB8rSM=" -> null
      - terraform_labels     = {
          - "goog-terraform-provisioned" = "true"
        } -> null
      - zone                 = "asia-northeast3-c" -> null
...

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

google_compute_instance.default: Destroying... [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm]
google_compute_instance.default: Still destroying... [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm, 10s elapsed]
...
google_compute_instance.default: Still destroying... [id=projects/gcp-in-ca/zones/asia-northeast3-c/instances/terraform-test-vm, 1m50s elapsed]
google_compute_instance.default: Destruction complete after 1m52s

Destroy complete! Resources: 1 destroyed.


```
