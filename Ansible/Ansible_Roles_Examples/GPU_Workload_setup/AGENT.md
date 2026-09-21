# GPU Workload Settings 작업 지침

NVIDIA GPU 서버 구성을 용도별 Ansible Role로 관리한다. 이전의 단일 `gpu_setup` Role과 `gpu_setup_profile` 방식은 사용하지 않는다.

## Role 구조

```text
roles/
├── gpu_common/
├── gpu_standalone/
├── gpu_docker/
├── gpu_kubernetes/
└── gpu_slurm/
```

- `gpu_common`: Ubuntu 사전 준비, NVIDIA 저장소, Driver, CUDA, cuDNN, NVIDIA Container Toolkit 패키지와 reboot 판정
- `gpu_standalone`: Python virtualenv, PyTorch, TensorFlow
- `gpu_docker`: Docker Engine과 NVIDIA Docker runtime
- `gpu_kubernetes`: 기존 containerd의 NVIDIA runtime 구성
- `gpu_slurm`: 기존 Slurm Compute Node의 `gres.conf`과 선택적 `cgroup.conf`

환경 Role은 `include_role`로 `gpu_common`을 호출한다. 공통 구현을 각 Role에 복사하지 않는다.

## 지원 범위

- Ubuntu 20.04, 22.04, 24.04
- x86_64, aarch64/SBSA
- NVIDIA Driver, CUDA, 선택적 cuDNN
- Docker와 NVIDIA Container Toolkit
- Kubernetes Worker Host runtime 설정
- Slurm Compute Node GPU 설정
- 설치 후 읽기 전용 검증

다음은 범위에 포함하지 않는다.

- RHEL/Rocky Linux
- Kubernetes/kubelet/containerd 자체 설치
- NVIDIA Device Plugin 또는 GPU Operator 배포
- Slurm Controller와 `slurm.conf` 구성
- MIG, MPS, GPU Time Sharing, DCGM/Prometheus

## 설계 원칙

- 실제 설치 로직은 용도별 task 파일로 분리하고 `tasks/main.yml`은 orchestration만 담당한다.
- Shell보다 Ansible 기본 모듈을 우선한다.
- Shell/command가 필요하면 상태 검사, `creates`, `changed_when`으로 멱등성을 보호한다.
- Docker Role은 호스트 CUDA와 cuDNN을 설치하지 않는다.
- `kubernetes_gpu_driver_managed: true`이면 Role의 Driver 설치를 건너뛴다.
- Kubernetes Device Plugin과 GPU Operator는 Cluster Layer 책임이다.
- Slurm 기존 설정 보호를 위해 `cgroup.conf` 관리와 `slurmd` 재시작은 기본 비활성이다.
- Role은 기본적으로 reboot하지 않고 `gpu_reboot_required`로 필요 여부를 알린다.
- 공통 preflight는 읽기 전용으로 실행하며, DCGM은 환경별 optional task로만 제공한다.
- Kubernetes의 DCGM/DCGM Exporter는 GPU Operator 또는 Helm 등 Cluster Layer가 관리한다.
- 설정 변경이 없다면 재실행 결과 `changed=0`을 목표로 한다.

## 안전 기본값

```yaml
gpu_allow_reboot: false
gpu_verify_installation: true
gpu_verify_fail_on_error: true
slurm_manage_cgroup_conf: false
slurm_restart_daemon: false
```

Driver install/upgrade, initramfs 갱신, Docker/containerd 재시작, Slurm daemon 재시작은 disruptive operation이다. 실행 중인 workload와 클러스터 drain 절차를 고려한다.

## 문서

전체 구조, 변수, 실행 흐름과 예제는 저장소 루트 `README.md`에 기록한다. 각 Role의 `README.md`에는 해당 Role의 책임과 최소 사용 예제를 유지한다.

`playbooks/main.yaml`은 네 Inventory 그룹을 각 환경 Role에 연결하는 기본 실행 Playbook이다. `inventory/inventory.example.yaml`은 문서용 IP 주소를 사용하는 예시이며 실제 실행 전 별도의 Inventory로 복사해 수정한다. 운영자가 조정할 변수는 `inventory/group_vars/all.yaml` 한 파일에 모아 관리한다.

## 검증 체크리스트

1. 각 환경 Role이 필요한 공통 컴포넌트만 요청하는가
2. Docker Role이 Host CUDA/cuDNN을 설치하지 않는가
3. Kubernetes Managed Driver 환경에서 Driver를 중복 설치하지 않는가
4. Driver 변경 시 명시적 허용 없이 reboot하지 않는가
5. Slurm 기존 설정과 daemon을 기본적으로 불필요하게 변경하지 않는가
6. 템플릿, include, handler 참조가 모두 유효한가
7. 대상 노드에서 두 번째 실행이 `changed=0`에 수렴하는가
