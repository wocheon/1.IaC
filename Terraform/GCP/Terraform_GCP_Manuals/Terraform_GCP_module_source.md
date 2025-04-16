# Terraform 모듈 Source 지정 

## Terraform 모듈 Source ?
- Terraform 모듈 사용시 모듈의 source를 지정할수 있음
    - 주요 사용 저장소 
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

```json
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
```
module "gce_disk" {
# Local File system
  source = "../modules/gce_disk"

  
```

### Github/Gitlab
```
module "gce_disk" {

# GitHub_Usage = git::https://github.com/[git_repo].git//[디렉토리 위치]?ref=[브랜치명]
  source = "git::https://github.com/wocheon/1.IaC.git//Terraform/GCP/Terraform_GCP_modules/modules/gce_disk?ref=master"

}
```

### Google Cloud Storage (GCS)
```
module "gce_disk" {
# GCS_Usage = gcs::https://www.googleapis.com/storage/v1/BUCKET_NAME/PATH_TO_MODULE
  source = "gcs::https://www.googleapis.com/storage/v1/terraform-module-bucket-wocheon07/modules/gce_disk.zip"
}
```

### AWS S3 
```
module "gce_disk" {
# GCS_Usage = gcs::https://www.googleapis.com/storage/v1/BUCKET_NAME/PATH_TO_MODULE
  source = "gcs::https://www.googleapis.com/storage/v1/terraform-module-bucket-wocheon07/modules/gce_disk.zip"
}
```

### Terraform Cloud

```
module "gce_disk" {
# GCS_Usage = gcs::https://www.googleapis.com/storage/v1/BUCKET_NAME/PATH_TO_MODULE
  source = "gcs::https://www.googleapis.com/storage/v1/terraform-module-bucket-wocheon07/modules/gce_disk.zip"
}
```