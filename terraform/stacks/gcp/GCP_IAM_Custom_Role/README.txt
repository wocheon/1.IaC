# GCP 커스텀 Role 권한 편집
- GCP의 커스텀 ROLE의 권한을 편집할수있는 TF파일 
    - 커스텀만 가능하며, 기존 권한은 수정 불가 
    
# 사용방법
1. GCP 콘솔 등에서 Role ID를 확인 후 terraform.tfvars 파일에 입력
2. terraform_import.sh을 통해 해당 Role을 Import
3. 해당 ROLE에 추가할 권한을 목록에 추가후 Plan/Apply
