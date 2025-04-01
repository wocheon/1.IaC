# Terraform Import 

## 개요 
- Terraform으로 관리되지 않는 리소스를 Import하여, Terraform으로 관리할수 있도록 변경하는 방법
- Import 된 리소스는 Terraform을 통해 변경/삭제 가능
- 테스트 환경 : AWS 
    - GCP도 동일 방식을 통해 적용가능 

## Terraform Import 
- 기존 리소스 Import를 위해 AWS 콘솔에서 테스트용 EC2 VM 생성
    - VM 명(tag) : aws-terraform-import-testvm
    - 인스턴스 유형 : t2.micro
    - OS : Ubuntu 22.04
    - VM_IP : 192.168.2.25
    - tags : 
        - Name : aws-terraform-import-testvm
        - User : ciw0707

### Terraform Import를 위한 Main.tf 작성 
> main.tf
```json
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "import_vm" {
}
```

### Terraform Import 실행 
```tf
# AWS
terraform import aws_instance.import_vm [Instance_ID]
#ex) terraform import aws_instance.import_vm i-0b2xxxxxxxxxxx

# GCP
terraform import google_compute_instance.import_vm [VM_selfLink]
#Ex) terraform import google_compute_instance.import_vm projects/${pjt_name}/zones/${VM_ZONE}/instance/${VM_NAME}
```
- AWS EC2 인스턴스 Import시 Instance_id를 명시
- GCP VM 인스턴스  Import시 VM의 SelfLink를 명시 (VM 세부정보 > 상응하는 코드에서 확인가능)


#### Terraform import 성공시 출력 내용
```
aws_instance.import_vm: Importing from ID "i-0b2xxxxxxxxxxx"...
aws_instance.import_vm: Import prepared!
  Prepared aws_instance for import
aws_instance.import_vm: Refreshing state... [id=i-0b2xxxxxxxxxxx]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```


### Terraform Import된 리소스의 TF파일 구성
- `terraform Import` 수행시 해당 리소스의 정보가 terraform.tfstate에 기록됨

- `terraform show` 명령을 통해 가져온 리소스의 상세 정보를 출력 가능 

```sh 
root@aws-test-vm-ciw0707:~/workspaces/terraform/aws_import_vm# terraform show
# aws_instance.import_vm:
resource "aws_instance" "import_vm" {
    ami                                  = "ami-xxxxxxxxxxxxxxx"
    arn                                  = "arn:aws:ec2:ap-northeast-2:xxxxxxxxxxxx:instance/i-0fca6575c4921ce9d"
    associate_public_ip_address          = true
    availability_zone                    = "ap-northeast-2a"
    cpu_core_count                       = 1
    cpu_threads_per_core                 = 1
    disable_api_stop                     = false
    disable_api_termination              = false
    ebs_optimized                        = false
    get_password_data                    = false
    hibernation                          = false
    host_id                              = null
    iam_instance_profile                 = null
    id                                   = "i-xxxxxxxxxxxxxxxxxx"
    instance_initiated_shutdown_behavior = "stop"
    instance_lifecycle                   = null
    instance_state                       = "running"
    instance_type                        = "t2.micro"
    ipv6_address_count                   = 0
    ipv6_addresses                       = []
    key_name                             = "xxxxxxxxxxxxx"
    monitoring                           = false
    outpost_arn                          = null
    password_data                        = null
    placement_group                      = null
    placement_partition_number           = 0
    primary_network_interface_id         = "eni-xxxxxxxxxxxxxxxxx"
    private_dns                          = "ip-192-168-2-132.ap-northeast-2.compute.internal"
    private_ip                           = "192.168.2.132"
    public_dns                           = null
    public_ip                            = "x.xx.xx.xxx"
    secondary_private_ips                = []
    security_groups                      = []
    source_dest_check                    = true
    spot_instance_request_id             = null
    subnet_id                            = "subnet-xxxxxxxxxxxxxxx"
    tags                                 = {
        "Name" = "aws-terraform-import-testvm"
        "user" = "ciw0707"
    }
    tags_all                             = {
        "Name" = "aws-terraform-import-testvm"
        "user" = "ciw0707"
    }
........
```
- 해당 출력값을 복사하여 main.tf에 복사 or 신규 TF 파일을 생성 
    - 생성 후 terraform plan 명령을 실행하여 변경 불가능한 변수값 확인 후 제외 

- TF 파일이 정상적으로 구성되면 `terraform plan` 시 다음과 같이 출력 
```sh
root@aws-test-vm-ciw0707:~/workspaces/terraform/aws_import_vm# terraform plan
aws_instance.import_vm: Refreshing state... [id=i-xxxxxxxxxxxxxx]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## Terraform Import 리소스 변경 
- Import 완료된 리소스에 변경사항을 적용 
    - tag 추가 
        - terraform_import = y

- main.tf의 tags부분에 다음 내용 추가 
> main.tf
```json
...
    tags                                 = {
        "Name" = "aws-terraform-import-testvm"
        "user" = "ciw0707"
        "terraform_import" = "y" # 신규 tag 추가
    }
...    
```

### terraform plan 확인 
```sh
root@aws-test-vm-ciw0707:~/workspaces/terraform/aws_import_vm# terraform plan
aws_instance.import_vm: Refreshing state... [id=i-xxxxxxxxxxxxxxxx]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_instance.import_vm will be updated in-place
  ~ resource "aws_instance" "import_vm" {
        id                                   = "i-xxxxxxxxxxxxxxxx"
      ~ tags                                 = {
            "Name"             = "aws-terraform-import-testvm"
          + "terraform_import" = "y"
            "user"             = "ciw0707"
        }
      ~ tags_all                             = {
          + "terraform_import" = "y"
            # (2 unchanged elements hidden)
        }
      + user_data_replace_on_change          = false
        # (37 unchanged attributes hidden)

        # (8 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

### terraform apply로 변경사항 적용 
- AWS 콘솔 내 EC2 인스턴스에서 신규 태그 추가 확인 

## Terraform Import 리소스 삭제 (Destory)
- Import된 리소스는 Terraform으로 관리되므로 destory시 리소스가 삭제됨

```sh
# Destory 전
Name                            InstanceId          InstanceType    State       AvailabilityZone
aws-test-vm-ciw0707             i-xxxxxxxxxxxxx     t2.small        running     ap-northeast-2a
aws-terraform-import-testvm     i-xxxxxxxxxxxxx     t2.micro        running     ap-northeast-2a
```

### Terraform Destroy 실행 
```sh 
root@aws-test-vm-ciw0707:~/workspaces/terraform/aws_import_vm# terraform destory
Terraform has no command named "destory". Did you mean "destroy"?

To see all of Terraform's top-level commands, run:
  terraform -help

root@aws-test-vm-ciw0707:~/workspaces/terraform/aws_import_vm# terraform destroy
aws_instance.import_vm: Refreshing state... [id=i-xxxxxxxxxxxxx]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_instance.import_vm will be destroyed
  - resource "aws_instance" "import_vm" {

....

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_instance.import_vm: Destroying... [id=i-xxxxxxxxxxxxx]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 10s elapsed]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 20s elapsed]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 30s elapsed]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 40s elapsed]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 50s elapsed]
aws_instance.import_vm: Still destroying... [id=i-xxxxxxxxxxxxx, 1m0s elapsed]
aws_instance.import_vm: Destruction complete after 1m0s

Destroy complete! Resources: 1 destroyed.
```

- tf파일을 그대로 두고 apply 하면 그대로 재생성가능 