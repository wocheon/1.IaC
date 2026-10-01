# GCE 단일 GPU VM

기존 `gce-vm-cluster`의 `gce_instance` 모듈을 사용해 GPU workload 테스트용
VM 1대를 생성한다.

- 머신 타입: `n1-standard-4`
- GPU: NVIDIA T4 1개 (`nvidia-tesla-t4`)
- zone: `asia-northeast3-b`
- 내부 IP: `10.1.1.33`
- OS: 일반 Ubuntu 24.04 LTS
- host maintenance: `TERMINATE`

일반 Ubuntu 이미지를 사용하므로 NVIDIA 드라이버는 설치되어 있지 않다.
VM 생성 후 GPU workload 설치 과정에서 드라이버를 별도로 구성한다.

서울 리전의 N1+T4는 `asia-northeast3-b`와 `asia-northeast3-c`에서 사용할
수 있다. `asia-northeast3-a`는 N1+T4를 지원하지 않는다.

## 실행

```bash
cd terraform/gce-gpu-vm
terraform init
terraform plan
terraform apply
```

환경에 맞게 `terraform.tfvars`의 프로젝트, 서비스 계정, 네트워크, 서브넷,
내부 IP를 확인한 뒤 실행한다. 프로젝트에 NVIDIA T4 GPU quota도 필요하다.

생성 후 GPU 장치와 드라이버 미설치 상태는 다음처럼 확인할 수 있다.

```bash
lspci | grep -i nvidia
nvidia-smi
```

`lspci`에는 NVIDIA 장치가 표시되고, 드라이버 설치 전 `nvidia-smi`가 없거나
GPU와 통신하지 못하는 상태가 정상이다.

## 삭제

```bash
terraform destroy
```
