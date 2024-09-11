# Hashicorp Packer 

## 개요 
- Hashicorp Packer란? 
    - 자동화된 이미지를 만들기 위한 오픈소스 도구 
    - 여러 플랫폼에서 사용가능한 머신이미지를 자동으로 생성 가능 

- 주요 특징
    - Multi Provider 지원 
        - 여러 클라우드 제공업체 및 가상화 플랫폼 지원 
        - AWS, GCP, Azure, VMware, VirtualBox 등 에서 이미지 생성 가능

    - 자동화된 이미지 빌드 
        - 이미지 빌드 과정을 자동화하여 모든환경에서 일관된 이미지를 생성

    - 다양한 Provisioner를 지원
        -  shell, ansible, chef, puppet, salt 등 여러 프로비저너를 통해 이미지 빌드과정에서 명령 실행 가능 

    - 템플릿 형식 지원 
        - JSON 및 HCL(HashiCorp Configuration Language) 형식 지원 

## Packer 템플릿 구성 

1. Packer 
    - 특정 플러그인 사용시에 명시하여 플러그인을 사용가능 
    - 각 플러그인별로 명시 방법이 다르므로 docs 참고

2. Source 
    - 이미지의 소스를 정의하는 내용 
    - Packer는 소스 이미지를 기반으로하여 새로운 이미지를 생성 
    - GCP, AWS 등의 Public Cloud의 경우 Source 정보를 기반으로 VM을 생성하여 Build 작업 후에 이미지를 생성하는 식으로 수행됨

3. Build
    - 소스 이미지를 기반으로 Provisoner를 통해 작업을 수행
    - Public Cloud의 경우 외부IP를 가지는 VM을 생성하고 SSH로 붙어서 작업을 수행하는 형태 



## Packer 설치 
- 공식 문서 참고
    - https://developer.hashicorp.com/packer/install

- CentOS7의 경우 repo 이슈가 있으므로 바이너리 파일을 다운로드하여 설치
    - 기존 cracklib-packer가 packer로 심볼릭링크가 걸려있으므로 이를 해제 해제 해야함

    ```sh
    $ which packer 
    /sbin/packer 

    $ ll /sbin/packer  
    lrwxrwxrwx. 1 root root 15 May 12 2021 /sbin/packer -> cracklib-packer 

    $ rm -rf /sbin/packer
    ```

### Packer 설치 (바이너리)
```sh
$ wget https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_386.zip
$ unzip packer_1.11.2_linux_386.zip
$ mv packer /usr/bin/

$ packer -v
Packer v1.11.2
```


### Packer 작업공간 생성 
- packer는 Service_account_key 파일을 통해 GCP에 접근하므로 Key파일을 해당 디렉토리에 넣어줘야함

```sh
$ mkdir hashicorp_packer ; cd hashicorp_packer
```



#### hcl 파일 생성 

- hcl파일 명명 규칙 
    - [파일명].pkr.hcl

- "# Packer Configuration for Google Cloud Platform " 주석을 붙여야 Vim에서 양식을 인식함

> vim example.pkr.hcl
```h
# Packer Configuration for Google Cloud Platform
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

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

variable "image_name" {
  description = "The name of the image"
  default     = "packer-image-240911"
}

variable "network" {
  description = "Builder VMs Network"
  default     = "test-vpc-1"
}

variable "subnetwork" {
  description = "Builder VMs Subnetwork"
  default     = "test-vpc-sub-01"
}


source "googlecompute" "example" {
  credentials_file   = "service-account.json"
  project_id     = var.project_id
  zone         = var.zone
  source_image   = "ubuntu-2004-focal-v20240830"
  image_family   = "my-image-family"
  image_name     = var.image_name
  machine_type  = "e2-small"
  ssh_username    = "packer"
  image_storage_locations = [var.region]
  network    = var.network
  subnetwork = var.subnetwork

}

build {
  sources = ["source.googlecompute.example"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
```


#### packer 작업공간 선언 
```
$ packer init 
```

#### 변수 템플릿용 hcl파일 생성 
    - 필요 시 따로 변수 템플릿 파일을 만들어서 사용가능 

> vi variables.pkr.hcl
```h
# Packer Configuration for Google Cloud Platform
project_id = "gcp-in-ca"
region = "asia-northeast3"
image_name = "packer-image-240911"
network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
```


### Packer Syntax Check
```sh
$ packer validate -var-file variables.pkr.hcl  example.pkr.hcl
The configuration is valid.
```

### Packer build 

- Packer 빌드 과정

1. 이미지를 만들기 위해 Packer가 ServiceAccount File을 통해 임시 VM을 생성 (source 부분을 토대로 VM을 생성함)
    
2. 외부 IP에 SSH로 해당 VM에 연결

3. provisioner를 통해 빌드부분에 명시된 작업을 수행 
    - 에러 발생시 자동으로 모든 작업이 취소되며, VM과 디스크도 자동으로 삭제됨

4. 작업 완료 후 디스크는 유지하면서 임시 VM 삭제 

5. 이미지 생성 

6. 정상적으로 이미지 생성되면 디스크 삭제 

```sh
$ packer build -var-file variables.pkr.hcl  example.pkr.hcl
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
    googlecompute.example: IP: 34.64.182.94
==> googlecompute.example: Using SSH communicator to connect: 34.64.182.94
==> googlecompute.example: Waiting for SSH to become available...
==> googlecompute.example: Connected to SSH!
==> googlecompute.example: Provisioning with shell script: /tmp/packer-shell1258504077
    googlecompute.example: Hit:1 http://asia-northeast3.gce.archive.ubuntu.com/ubuntu focal InRelease
    googlecompute.example: Get:2 http://asia-northeast3.gce.archive.ubuntu.com/ubuntu focal-updates InRelease [128 kB]

......


    googlecompute.example: Processing triggers for libc-bin (2.31-0ubuntu9.16) ...
==> googlecompute.example: Deleting instance...
    googlecompute.example: Instance has been deleted!
==> googlecompute.example: Creating image...
==> googlecompute.example: Deleting disk...
    googlecompute.example: Disk has been deleted!
Build 'googlecompute.example' finished after 3 minutes 10 seconds.

==> Wait completed after 3 minutes 10 seconds

==> Builds finished. The artifacts of successful builds are:
--> googlecompute.example: A disk image was created in the 'gcp-in-ca' project: packer-image-240911
```

### Packer로 생성된 이미지 삭제 

- Terraform의 Destory와 같은 기능은 없으며 GCP 콘솔 혹은 gcloud를 통해 직접 삭제 필요
```
$ gcloud compute image delete packer-image-240911
```
