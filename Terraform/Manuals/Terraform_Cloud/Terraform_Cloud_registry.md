# Terraform Registry 

## Terraform Registry ?
- Terraform에서 사용하는 모듈과 프로바이더들을 공유하고 재사용할 수 있도록 해주는 공식 저장소(registry)기능
- 각 Provider가 공식으로 지원하는 모듈을 확인 및 사용가능 
    
- 모듈 구성을 통해 인프라 구성 시 편의성 증대    
    - 이미 검증된 모듈을 사용하여 빠르게 인프라를 구성가능 
    - 코드 재사용성 증가

- 기본 사용 형식
    - Registry 내 모듈 경로를 Source로 지정
    - 모듈 버전을 명시 하지 않는 경우 최신 버전을 가져오지만, 안정성을 위해 사용
    ```json
    module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "3.14.0"
    }
    ```

## Terraform Registry / Terraform Cloud Registry 간 차이점
- Terraform에서 지원하는 Registry는 Terraform Registry 와 Terraform Cloud Registry가 존재

- 공개 저장소를 사용하는 경우 Terraform Registry, 비공개 저장소가 필요한경우 Terraform Cloud Registry를 사용

- 주요 차이점 
    | 항목                        | Terraform Registry (Public)        | Terraform Cloud Registry (Private)           |
    |----------------------------|------------------------------------|---------------------------------------------|
    | 접근성                    | 누구나 사용 가능 (공개)             | 조직 내 사용자만 접근 가능 (비공개)         |
    | 배포 대상                | 전 세계 Terraform 사용자           | 특정 Terraform Cloud 조직 내 사용자         |
    | 모듈 업로드 방식           | GitHub 공개 저장소 연동 필요        | GitHub, GitLab 등과 연동, 비공개 가능        |
    | 권한 관리                 | 불가능                             | 조직/팀 단위로 모듈 접근 제어 가능           |


## Terraform Registry (Public) 사용 방법

### 모듈 업로드를 위한 github repository 생성
- Terraform Registry와 연동을 위한 Repository 명칭 규칙
    - EX) AWS용 VPC 모듈 : terraform-aws-vpc
    - 규칙에 맞지않는 Repository는 인식 불가
```
terraform-<PROVIDER>-<NAME>
```
- 신규 Github Repository 구성 
    - Repository 명 : terraform-gcp-module-registry
    - 내부 구성
        - Submodule로 구성하여 모듈 추가를 용이하도록 구성
        - README 파일을 추가하여 메뉴얼 구성
    ```
    📦terraform-gcp-module-registry
    ┃ ┗ 📜README.md
    ┗ 📂modules
       ┗ 📂gce_disk
         ┣ 📜main.tf
         ┣ 📜output.tf
         ┗📜variables.tf
    ```
    - Terraform Reigstry에 업로드를 위해서는 최소 1개 이상의 tag가 필요
    ```sh
    # Git Commit&Push
    git init
    git add . 
    git branch -M main
    git commit -m "1st Commit"
    git push origin main

    # Git Add Tag 
    ## git log로 Commit_id 확인
    git log 

    ## tag 생성 - Commit을 지정하지 않으면 자동으로 최신 커밋을 통해 Push
    git tag v1.0.0 [commit_id]

    ## tag를 지정하여 Push
    git push origin v1.0.0
    ```
### Terrform registry에 모듈 업로드 

- Terraform Registry에 접속 및 로그인
    - https://registry.terraform.io/
        - github 연동을 통해 로그인

- 우측 상단 Publish > Moudle 선택
    <img src="images/tr_module_publish_1.png" width="80%" height="100%">

- 생성된 Registry를 선택 하여 배포
    <img src="images/tr_module_publish_2.png" width="80%" height="100%">

- 배포 완료 및 구성 확인
    <img src="images/tr_module_publish_3.png" width="80%" height="100%">
    
- 수정 사항 반영 
    - Manage Module -> Resync Module

- 삭제 
    - 특정 버전만 삭제 
        - 버전 선택 후 Manage Module -> Delete Module Version
    - 전체 삭제 
        - 버전 선택 후 Manage Module -> Delete Module

### Terraform Registry의 모듈 사용
- 모듈 사용시 다음과 같이 Source를 지정 
    - Public Registry이므로 별도 인증절차 없이 사용가능
```
module "module-registry" {
  source  = "wocheon/module-registry/gcp"
  version = "1.0.0"
}
```

## Terraform Cloud Registry 사용 방법

### 모듈 업로드를 위한 github repository 생성

### Terrafrom registry 생성 
- Tag 기반
- Branch 기반

### 버전 업데이트 
- Tag 기반
- Branch 기반
