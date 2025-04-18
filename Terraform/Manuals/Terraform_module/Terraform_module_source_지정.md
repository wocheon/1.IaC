# Terraform 모듈 Source 지정 

## Terraform 모듈 Source ?
- Terraform 모듈 사용시 모듈의 source를 지정할수 있음
    - 사용 가능한 Source 옵션
        - Local File System (Default)
        - Terraform Registry
        - GITHUB, GITLAB
        - Bitbucket
        - HTTP/HTTPS
        - AWS S3 
        - GCP Cloud Storage
        - Azure Storage
    - AWS CodeCommit, GCP Source Repositories 등의 소스 저장소의 경우 인증 방식이 달라 직접 연결 불가
        - 굳이 사용한다면 로컬에 복사하여 사용하는 식으로 사용

## Moudule 소스 지정 예시 

```hcl
module "gce_disk" {

# Local File system
  source = "../modules/gce_disk"

# GitHub Source
#  source = "git::https://github.com/wocheon/1.IaC.git//Terraform/GCP/Terraform_GCP_modules/modules/gce_disk?ref=master"

# Google Cloud Storage Source
#  source = "gcs::https://www.googleapis.com/storage/v1/terraform-module-bucket-wocheon07/modules/gce_disk.zip"

  new_disk_name         = var.new_disk_name
  new_disk_zone         = var.new_disk_zone
  new_disk_type         = var.new_disk_type
  new_disk_size         = var.new_disk_size
  new_disk_labels       = var.new_disk_labels
### Source Configurations ###
  new_disk_image_id              = var.new_disk_image_id
  new_disk_snapshot_id           = var.new_disk_snapshot_id
}
```

## 각 Source 별 지정방법

### Local File System
- 모듈의 위치를 절대 경로 혹은 상대경로를 사용하여 표기 
  - 주로 상대경로를 사용하여 표기 (절대경로는 CI/CD 연동시 오류 발생)

- 사용 예시
  ```
  module "gce_disk" {
  # Local File system
    source = "../modules/gce_disk"
  }  
  ```

### Github/Gitlab
- gitlab 혹은 github에 모듈을 업로드 후, 해당 모듈을 불러와서 사용하는 방법
- 저장소 명, 모듈 위치를 지정하고 브랜치 혹은 Tag를 명시하여 불러옴

- 사용 예시
  
  ```hcl
  ### 기본 양식 ###
  # Github
  git::https://github.com/[git_repo].git//[디렉토리 위치]?ref=[브랜치명 or Tag]
  
  # Gitlab
  git::https://gitlab.com/[git_repo].git//[디렉토리 위치]?ref=[브랜치명 or Tag]
  
  ### 모듈내 지정 방법 ###
  module "gce_disk" {
    source = "git::https://github.com/wocheon/1.IaC.git//Terraform/GCP/Terraform_GCP_modules/modules/gce_disk?ref=master"
  }
  ```

### Google Cloud Storage (GCS)
- GCP의 Cloud Storage에 모듈을 업로드 하여 사용하는 방법
- zip파일만 지원하며 모듈 zip파일은 하위 디렉토리 없이 tf파일 만을 포함해야함
  ```
  # GCS 업로드용 모듈 zip파일 기본 구성
  module.zip
  - main.tf
  - variable.tf
  - output.tf
  ```

- 사용 예시
  ```hcl
  module "gce_disk" {
  # GCS_Usage = gcs::https://www.googleapis.com/storage/v1/BUCKET_NAME/PATH_TO_MODULE
    source = "gcs::https://www.googleapis.com/storage/v1/terraform-module-bucket-wocheon07/modules/gce_disk.zip"
  }
  ```

### AWS S3 
- AWS의 S3에 모듈을 업로드 하여 사용하는 방법
- GCP Cloud Storage 와 동일하게 Zip파일만 지원
  ```
  # AWS S3 업로드용 모듈 zip파일 기본 구성
  my-module.zip
  ├── main.tf
  ├── variables.tf
  ├── outputs.tf
  ```
- 사용 예시
 ```hcl
module "example" {
  # S3 Source 설정
  source = "s3::https://s3.amazonaws.com/<bucket-name>/<path-to-zip>"

  # 리전별 엔드포인트일 경우
  source = "s3::https://<bucket-name>.s3.<region>.amazonaws.com/<path-to-zip>"
}
```

### Terraform Cloud
- Terraform Cloud를 Source로 사용 시 모듈 버전 명시 필요 
- Terraform Cloud 연동이 필요하므로 `terraform login` 혹은 Credentials 구문을 추가 
  - API 토큰은 Terraform Cloud의 Account Settings > Token에서 발급가능 
```
credentials "app.terraform.io" {
  # valid user API token
  token = "xxxxxx.atlasv1.zzzzzzzzzzzzz"
}
```

```hcl
module "module-repo_gce_disk" {
  source  = "app.terraform.io/gcp_terraform_wocheon07/module-repo/google//modules/gce_disk"
  version = "1.1.2"
}
```