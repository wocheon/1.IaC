# Terraform 내 Backend 지정 

## Terraform의 backend
- Terraform 상태 파일(terraform.tfstate)을 저장하는 위치를 정의하며, 상태 파일의 공유, 버전 관리, 백업 등을 처리

- 사용 가능한 Backend 옵션
    - Local File System (Default)
    - Terraform Cloud Workspace
    - AWS S3 
    - GCP Cloud Storage

### Local File System

```
terraform {
  backend "local" {
    path = "path/to/terraform.tfstate"
  }
}
```

### AWS S3

```
terraform {
  backend "s3" {
    bucket = "my-tf-state-bucket"
    key    = "path/to/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Google Cloud Storage

```
terraform {
  backend "gcs" {
    bucket = "my-tf-state-bucket"
    prefix = "terraform/state"
  }
}
```

### Terraform Cloud Workspace

```
terraform {
  backend "remote" {
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}
```