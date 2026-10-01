# Infrastructure as Code examples

Ansible, Terraform, Packer 학습 자료와 실행 예제를 모아 둔 저장소입니다.

## Directory guide

- [`ansible/playbooks`](ansible/playbooks): 독립 실행형 플레이북
- [`ansible/roles`](ansible/roles): 재사용 가능한 역할과 역할 기반 예제
- [`ansible/examples`](ansible/examples): 서비스·플랫폼별 Ansible 예제
- [`terraform/modules`](terraform/modules): AWS 및 GCP 재사용 모듈
- [`terraform/stacks`](terraform/stacks): 모듈을 조합하는 루트 구성
- [`terraform/examples`](terraform/examples): 독립 실행형 Terraform 예제
- [`packer/examples`](packer/examples): Packer와 Ansible 연동 예제
- [`docs`](docs): 도구별 사용 설명서
- [`scripts`](scripts): 저장소 관리 보조 스크립트
- [`archive`](archive): 이전 버전 참고 자료

## Local values

실제 환경값은 Git에 커밋하지 않습니다. 필요한 디렉터리에서 예제 파일을 복사해 사용합니다.

```bash
cp terraform.tfvars.example terraform.tfvars
```

Terraform 상태 파일, 로컬 변수 파일, Ansible 로그와 인증정보는 `.gitignore`로 제외됩니다.

## Line endings

셸 및 IaC 파일은 WSL, Linux, Git Bash에서 함께 사용할 수 있도록 LF 줄바꿈을 사용합니다. 관련 규칙은 `.gitattributes`와 `.editorconfig`에 정의되어 있습니다.
