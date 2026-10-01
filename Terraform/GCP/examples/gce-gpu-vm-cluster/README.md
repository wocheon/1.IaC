# GCE GPU/Non-GPU VM 클러스터

control-plane 한 대와 서로 독립적인 GPU/Non-GPU worker pool을 생성한다.
두 worker module은 각각 count 변수를 가지며 한쪽을 0으로 비활성화하거나
두 종류를 동시에 생성할 수 있다.

| 역할 | 수량 변수 | 기본 머신 타입 | GPU | 기본 Zone |
|---|---|---|---|---|
| control-plane | 1대 고정 | `e2-medium` | 없음 | `asia-northeast3-a` |
| GPU worker | `gpu_worker_count` | `n1-standard-4` | T4 1개 | `asia-northeast3-b` |
| Non-GPU worker | `non_gpu_worker_count` | `e2-medium` | 없음 | `asia-northeast3-a` |

각 worker count는 0 이상의 정수다. 기본값은 GPU 2대, Non-GPU 0대이며
`terraform.tfvars.example`은 두 종류를 각각 1대씩 생성하는 혼합 구성을 보여준다.

모든 VM은 NVIDIA Driver가 포함되지 않은 Ubuntu 24.04 LTS 이미지
`ubuntu-os-cloud/ubuntu-2404-lts-amd64`를 사용한다. GPU worker의 Driver는
Ansible GPU Role로 별도 설치한다.

control-plane과 Non-GPU worker는 host maintenance 시 `MIGRATE`, GPU worker는
GPU VM 요구사항에 따라 `TERMINATE`를 사용한다.

## 주요 변수

```hcl
gpu_worker_zone         = "asia-northeast3-b"
gpu_worker_vm_name      = "gcp-an3-b-gpu-cluster-node"
gpu_worker_machine_type = "n1-standard-4"
gpu_worker_count        = 1

non_gpu_worker_zone         = "asia-northeast3-a"
non_gpu_worker_vm_name      = "gcp-an3-a-gpu-cluster-cpu-node"
non_gpu_worker_machine_type = "e2-medium"
non_gpu_worker_count        = 1
```

내부 IP는 control-plane 다음 주소부터 GPU worker, Non-GPU worker 순서로
연속 할당한다. 예를 들어 control-plane이 `10.1.1.40`이고 각 worker가 1대면
다음과 같다.

| 역할 | 내부 IP |
|---|---|
| control-plane | `10.1.1.40` |
| GPU worker | `10.1.1.41` |
| Non-GPU worker | `10.1.1.42` |

GPU worker 수를 변경하면 그 뒤에 배치되는 Non-GPU worker IP도 변경된다.

## 실행

```bash
cd terraform/gce-gpu-vm-cluster
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

실행 전에 프로젝트, 서비스 계정, 네트워크, 서브넷, 내부 IP와 VM 이름을 확인한다.
GPU worker를 생성할 때는 수량만큼 NVIDIA T4 quota가 있어야 하며 선택한 Zone에
실제 GPU capacity가 있어야 한다.

기존 GPU worker module 주소 `module.gce_gpu_worker`는 유지되므로 이 변경만으로
기존 GPU VM의 Terraform 주소가 바뀌지는 않는다. `non_gpu_worker_count`를 늘리면
`module.gce_non_gpu_worker` 리소스가 새로 생성된다.

## 출력

- `instance_name`, `instance_zone`, `internal_ip`, `external_ip`: control-plane,
  GPU worker, Non-GPU worker 순서의 통합 목록
- `gpu_workers`: GPU worker의 이름, Zone, 내부/외부 IP
- `non_gpu_workers`: Non-GPU worker의 이름, Zone, 내부/외부 IP

GPU worker 생성 후 Driver 설치 전 상태는 다음 명령으로 확인할 수 있다.

```bash
lspci | grep -i nvidia
nvidia-smi
```

`lspci`에는 NVIDIA 장치가 표시되고, Driver 설치 전 `nvidia-smi`가 없거나
GPU와 통신하지 못하는 상태가 정상이다.

## 삭제

```bash
terraform destroy
```
