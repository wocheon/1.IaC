# Packer & Ansible 

## 개요 
- Packer를 통해 이미지 생성시 Provisioner를 Ansible로 사용할 수 있음 
- Ansible-playbook을 실행하여 이미지를 세팅하고 이를 사용 가능 


## 테스트 순서
1. Packer 실행용 hcl 파일 작성
2. Packer를 통해 이미지 생성 요청 (Packer Build) 
3. Ansible을 Provisioner로 지정하여 Playbook 실행 
4. 이미지 생성 확인 
5. Terraform으로 해당 이미지를 부팅디스크로 하는 VM 생성 


## 디렉토리 구성도
```sh
├── ansible-playbooks   
│   ├── files # Ansible copy모듈로 복사할 파일들
│   │   ├── mariadb-10.5.10-linux-systemd-x86_64.tar.gz
│   │   ├── mariadb.service
│   │   ├── my.cnf
│   │   ├── mysqld_exporter-0.14.0.linux-amd64.tar.gz
│   │   └── mysqld_exporter.service
│   ├── mariadb_install_1.yaml # Provisioner를 통해 실행하는 playbook파일 #1
│   ├── mariadb_install_2.yaml # Provisioner를 통해 실행하는 playbook파일 #2
│   ├── mariadb_install_3.yaml # Provisioner를 통해 실행하는 playbook파일 #3
│   └── var_list.yml # Playbook 변수저장용 yml파일
├── install_mariadb.pkr.hcl # packer 실행용  hcl 파일
├── service-account.json    # GCP Service Acount Key 
└── variables.pkr.hcl       # packer 변수 저장용 hcl 파일
```



## hcl 파일 작성시 유의 사항


- packer Configuation에 googlecompute, ansible 명시 필요 

```tf
# Packer Configuration for Google Cloud Platform
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
    ansible = {
      source = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}
```

- variable의 경우 terraform의 tf파일과 달리 메인 hcl파일에 명시하여 사용해야함 
  - 변수 값을 지정하는 파일은 -var-file로 지정가능

> install_mariadb.pkr.hcl
```tf
variable "project_id" {
  description = "GCP Project ID"
  default     = "gcp-in-ca"
}

variable "region" {
  description = "GCP Region"
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  default     = "asia-northeast3-a"
}
```

> variables.pkr.hcl 

```tf
# Packer Configuration for Google Cloud Platform
project_id = "gcp-in-ca"
region = "asia-northeast3"
image_name = "packer-image-240919"
network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
```


- Source 부분의 remote_user 는 'root'를 사용 
    - 'gather_fact: true'인 경우 /root/.ansible/tmp 경로에 임시 디렉토리를 생성하려고 시도함
    - root계정이 아닌 경우 해당 부분에서 Permission Denied가 발생할 수 있음 
        - hcl파일의 Provisoner 부분에 become 옵션을 써봤으나 불가능
        - Playbook 파일에서 become 옵션을 사용해도 불가능

- Playbook의 hosts는 all 혹은 default로 설정 
    - localhost로 지정하는 경우 packer를 실행하는 VM에서 Playbook이 실행됨 
      - 생성되는 VM이 아니므로 주의

- hcl파일의 Provisioner - extra_arguments 에서 Inventory를 명시 
    - packer-provisioner-ansible이 제공하는 인벤토리 파일을 사용
    - packer로 생성된 vm를 대상으로 Playbook을 실행하게함
```tf
  extra_arguments = [
    "--inventory", "inventory"
  ]
```

- 변수 지정용 yml파일을 사용하는 경우 extra-vars로 지정 필요 

```tf
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml"    
  ]
```

- 서로 다른 Provisioner를 같이 사용 가능 

```tf
  provisioner "shell" {
    inline = [
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsqnZAQKBtydbn040mWetqauZ6Kx root@gcp-ansible-test' >> /root/.ssh/authorized_keys"
    ]
  }

  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_1.yaml"

  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"
  ]
  }
```

- playbook파일을 여러개 사용하는 경우 provisioner 블록을 추가하여 작성 가능

> 예시
```tf
  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_1.yaml"
  
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"    
  ]
  }

  provisioner "ansible" {
    playbook_file = "ansible-playbooks/mariadb_install_2.yaml"
  
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml",
    "--inventory", "inventory",
    "--become"    
  ]
  }
```


## Packer init
- 현 위치를 Packer 작업공간으로 선언
```sh
$ packer init
```



## Packer build 
- var-file을 지정하여 packer build 진행
  - `-var-file`로 해야함 (`--var-file`은 안됨)
```sh
$ packer build -var-file variables.pkr.hcl install_mariadb.pkr.hcl
```


### build 결과

```sh
 $ packer build -var-file variables.pkr.hcl install_mariadb.pkr.hcl
googlecompute.example: output will be in this color.

==> googlecompute.example: Checking image does not exist...
==> googlecompute.example: Creating temporary RSA SSH key for instance...
==> googlecompute.example: no persistent disk to create
==> googlecompute.example: Using image: ubuntu-2004-focal-v20240830
==> googlecompute.example: Creating instance...
    googlecompute.example: Loading zone: asia-northeast3-a
    googlecompute.example: Loading machine type: e2-small
    googlecompute.example: Requesting instance creation...
    googlecompute.example: Waiting for creation operation to complete...
    googlecompute.example: Instance has been created!
==> googlecompute.example: Waiting for the instance to become running...
    googlecompute.example: IP: 34.64.146.172
==> googlecompute.example: Using SSH communicator to connect: 34.64.146.172
==> googlecompute.example: Waiting for SSH to become available...
==> googlecompute.example: Connected to SSH!
==> googlecompute.example: Provisioning with shell script: /tmp/packer-shell2244545567
==> googlecompute.example: Provisioning with Ansible...
    googlecompute.example: Setting up proxy adapter for Ansible....
==> googlecompute.example: Executing Ansible: ansible-playbook -e packer_build_name="example" -e packer_builder_type=googlecompute --ssh-extra-args '-o IdentitiesOnly=yes' --extra-vars @ansible-playbooks/var_list.yml --inventory inventory --become -e ansible_ssh_private_key_file=/tmp/ansible-key448934341 -i /tmp/packer-provisioner-ansible2400331397 /root/workspaces/install_mariadb/packer/ansible-playbooks/mariadb_install_1.yaml
    googlecompute.example: [WARNING]: Unable to parse
    googlecompute.example: /root/IaC_tools/hashicorp_packer/install_mariadb/inventory as an inventory
    googlecompute.example: source
    googlecompute.example: [WARNING]: While constructing a mapping from
    googlecompute.example: /root/IaC_tools/hashicorp_packer/install_mariadb/ansible-
    googlecompute.example: playbooks/var_list.yml, line 2, column 1, found a duplicate dict key
    googlecompute.example: (exporter_password). Using last defined value only.
    googlecompute.example: [WARNING]: While constructing a mapping from
    googlecompute.example:
    googlecompute.example: /root/workspaces/install_mariadb/packer/ansible-playbooks/var_list.yml, line 2,
    googlecompute.example: PLAY [Packer - install MariaDB] ************************************************
    googlecompute.example: column 1, found a duplicate dict key (exporter_password). Using last defined
    googlecompute.example: value only.

......

    googlecompute.example: PLAY RECAP *********************************************************************
    googlecompute.example: default                    : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    googlecompute.example:
==> googlecompute.example: Deleting instance...
    googlecompute.example: Instance has been deleted!
==> googlecompute.example: Creating image...
==> googlecompute.example: Deleting disk...
    googlecompute.example: Disk has been deleted!
Build 'googlecompute.example' finished after 8 minutes 57 seconds.

==> Wait completed after 8 minutes 57 seconds

==> Builds finished. The artifacts of successful builds are:
--> googlecompute.example: A disk image was created in the 'gcp-in-ca' project: packer-image-240919
```

### 이미지 생성 확인
```sh
$ cloud compute images list --filter "(name:packer*)"
NAME                 PROJECT    FAMILY           DEPRECATED  STATUS
packer-image-240919  gcp-in-ca  my-image-family              READY
```