# NVIDIA GPU Server Ansible Roles

Ubuntu 기반 NVIDIA GPU 서버를 용도별 독립 Role로 구성한다. 사용자는 노드 유형에 맞는 환경 Role 하나를 선택하며, 각 환경 Role이 내부적으로 `gpu_common`을 호출한다.

## Role 구조

```text
roles/
├── gpu_common/       # 공통 Driver, CUDA, cuDNN, Container Toolkit 패키지
├── gpu_standalone/   # Python virtualenv, PyTorch, TensorFlow
├── gpu_docker/       # Docker Engine과 NVIDIA Docker runtime
├── gpu_kubernetes/   # Kubernetes Worker의 containerd GPU runtime
└── gpu_slurm/        # Slurm Compute Node의 GRES/cgroup GPU 설정
```

`gpu_common`은 공유 구현 Role이며 일반적으로 직접 적용하지 않는다. 기존 단일 Role의 `gpu_setup_profile` 변수는 제거되었다.

프로젝트의 실행 파일과 변수는 다음 위치에 있다.

```text
playbooks/main.yaml                  # 메인 Playbook
inventory/inventory.example.yaml    # 호스트와 그룹 예시
inventory/group_vars/all.yaml       # 전체 변수 제어 파일
ansible.cfg                         # roles/ 탐색 경로
```

`playbooks/main.yaml`은 Inventory의 네 노드 그룹을 각각 대응하는 환경 Role에 연결한다. Inventory 예시를 복사한 뒤 실제 호스트 주소로 변경하고, 설치 옵션은 `inventory/group_vars/all.yaml`에서 제어한다.

```bash
cp inventory/inventory.example.yaml inventory/inventory.yaml
ansible-playbook -i inventory/inventory.yaml playbooks/main.yaml
```

특정 환경만 적용하려면 Inventory 그룹 또는 태그로 제한할 수 있다.

```bash
ansible-playbook -i inventory/inventory.yaml playbooks/main.yaml --limit gpu_docker_nodes
ansible-playbook -i inventory/inventory.yaml playbooks/main.yaml --tags kubernetes
```

## 지원 환경

- Ubuntu 20.04, 22.04, 24.04
- `x86_64`, `aarch64`/SBSA
- NVIDIA CUDA apt repository 또는 Ubuntu 배포판 Driver 패키지
- Ansible fact gathering과 `become: true` 필요

## Role별 기본 구성

| 적용 Role | Driver | Host CUDA | Host cuDNN | Container Toolkit | 환경별 구성 |
|---|---:|---:|---:|---:|---|
| `gpu_standalone` | O | O | X | X | virtualenv, PyTorch, 선택적 TensorFlow |
| `gpu_docker` | O | X | X | O | Docker Engine, NVIDIA Docker runtime |
| `gpu_kubernetes` | O\* | X | X | O | 기존 containerd의 NVIDIA runtime |
| `gpu_slurm` | O | O | X | X | `gres.conf`, 선택적 `cgroup.conf` |

\* `kubernetes_gpu_driver_managed: true`이면 `gpu_common`의 Driver 설치를 건너뛴다.

## 사용 예제

Standalone VM:

```yaml
- hosts: gpu_vms
  become: true
  roles:
    - role: gpu_standalone
      vars:
        gpu_install_pytorch: true
        gpu_install_tensorflow: false
        gpu_python_venv_path: /opt/gpu-venv
```

Docker GPU Host:

```yaml
- hosts: gpu_docker_hosts
  become: true
  roles:
    - role: gpu_docker
      vars:
        docker_users:
          - ubuntu
```

Docker Role은 호스트 CUDA Toolkit을 설치하지 않는다. CUDA runtime은 컨테이너 이미지가 제공한다.

```bash
docker run --rm --gpus all nvidia/cuda:<version>-base-ubuntu22.04 nvidia-smi
```

Kubernetes GPU Worker:

```yaml
- hosts: gpu_workers
  become: true
  roles:
    - role: gpu_kubernetes
      vars:
        kubernetes_gpu_driver_managed: false
```

Cloud Provider가 Driver를 관리한다면 다음과 같이 사용한다.

```yaml
- role: gpu_kubernetes
  vars:
    kubernetes_gpu_driver_managed: true
```

이 Role은 Kubernetes, kubelet, NVIDIA Device Plugin 또는 GPU Operator를 배포하지 않는다. GPU Operator가 Driver와 Container Toolkit을 모두 관리한다면 `gpu_kubernetes`와 관리 범위가 겹치므로 함께 사용하지 않는다.

Slurm GPU Compute Node:

```yaml
- hosts: gpu_compute_nodes
  become: true
  roles:
    - role: gpu_slurm
      vars:
        slurm_gres_autodetect: nvml
        slurm_restart_daemon: false
```

Slurm Controller와 `slurm.conf`은 이 Role의 범위가 아니다.

## 공통 변수

환경 Role에서 다음 변수를 직접 덮어쓸 수 있다.

| 변수 | 기본값 | 설명 |
|---|---|---|
| `gpu_install_driver` | `true` | 해당 환경 Role에서 Driver 설치 |
| `nvidia_driver_version` | `560` | Driver 패키지 버전 계열 |
| `nvidia_driver_flavor` | `""` | proprietary 또는 `-open` |
| `nvidia_driver_source` | `cuda_repo` | `cuda_repo` 또는 `distro` |
| `gpu_install_cuda` | Role별 상이 | 호스트 CUDA Toolkit 설치 |
| `cuda_version` | `12.6` | CUDA Toolkit 버전 |
| `gpu_install_cudnn` | `false` | 호스트 cuDNN 설치 |
| `cudnn_version` | `""` | 빈 값이면 저장소 제공 버전 |
| `gpu_allow_reboot` | `false` | Driver 변경 후 자동 재부팅 허용 |
| `gpu_verify_installation` | `true` | 설치 후 읽기 전용 검증 |
| `gpu_verify_fail_on_error` | `true` | 검증 실패 시 Play 실패 |
| `gpu_preflight_enabled` | `true` | 공통 설치 전 환경 점검 |
| `gpu_install_dcgm` | `false` | Standalone/Slurm Host DCGM 설치 |
| `gpu_install_dcgm_exporter` | `false` | Docker DCGM Exporter 컨테이너 구성 |

운영 시 주로 변경하는 값은 `inventory/group_vars/all.yaml`에 모여 있다. 전체 기본값과 고급 변수는 각 Role의 `defaults/main.yml`을 참고한다.

## 실행 흐름

```text
gpu_standalone
  → gpu_common(Driver, CUDA, optional cuDNN)
  → Python virtualenv → PyTorch/TensorFlow → framework GPU 검증

gpu_docker
  → gpu_common(Driver, Container Toolkit package)
  → Docker Engine → daemon GPU runtime → Docker 검증

gpu_kubernetes
  → gpu_common(optional Driver, Container Toolkit package)
  → existing containerd GPU runtime → Kubernetes host 검증

gpu_slurm
  → gpu_common(Driver, CUDA, optional cuDNN)
  → gres.conf / optional cgroup.conf → Slurm host 검증
```

## Driver, CUDA, cuDNN 관계

```text
NVIDIA Driver
    ↓ 지원 가능한 CUDA 버전
CUDA Toolkit
    ↓ 빌드 대상 CUDA 계열
cuDNN
    ↓ 프레임워크 지원 조합
PyTorch / TensorFlow
```

Role은 전체 호환성 행렬을 내장하지 않는다. 운영 환경에서는 NVIDIA와 프레임워크의 공식 호환성 표를 확인하고 버전을 고정해야 한다. PyTorch CUDA wheel과 `tensorflow[and-cuda]`는 필요한 runtime 라이브러리를 virtualenv에 포함하므로 호스트 cuDNN은 기본 비활성이다.

## 멱등성과 설정 소유권

- 패키지는 `state: present`, virtualenv는 `creates`를 사용한다.
- apt repository와 템플릿은 내용이 바뀔 때만 변경된다.
- `nvidia-ctk`는 기존 runtime 설정을 확인한 뒤 필요한 경우에만 실행한다.
- Docker 설정 변경 시에만 Docker handler가 실행된다.
- `docker_manage_daemon_json: true`이면 Role이 `/etc/docker/daemon.json` 전체를 소유한다.
- Slurm `gres.conf` 변경 전에는 backup을 남긴다.
- 기존 `cgroup.conf` 보호를 위해 `slurm_manage_cgroup_conf` 기본값은 `false`이다.
- 실행 중인 Job 보호를 위해 `slurm_restart_daemon` 기본값은 `false`이다.

## Preflight와 선택적 DCGM

`gpu_common/tasks/preflight.yml`은 설치 전에 Secure Boot, kernel headers, kernel module 충돌, 기존 Driver, device node, 디스크 여유 공간과 CUDA/Driver 최소 호환성을 점검한다. 최초 설치를 막지 않도록 대부분 경고이며, 디스크 부족 실패는 `gpu_preflight_fail_on_low_disk`로 명시적으로 활성화한다.

DCGM은 환경별 수명주기가 달라 공통 Role에서 자동 설치하지 않는다.

- Standalone/Slurm: `gpu_install_dcgm: true`일 때 Host 패키지와 `nvidia-dcgm` 서비스 구성
- Docker: `gpu_install_dcgm_exporter: true`일 때 고정 image tag로 systemd 관리 컨테이너 구성
- Kubernetes: Node Role에서 설치하지 않고 GPU Operator 또는 Helm이 관리

DCGM 진단과 Docker Exporter는 모두 기본 비활성이다. `dcgmi diag`는 GPU를 실제로 사용하므로 workload 종료 또는 Slurm/Kubernetes drain 후 실행해야 한다.

동일 입력으로 두 번째 실행 시 `changed=0`을 목표로 한다. 실제 멱등성은 대상 Ubuntu/GPU 테스트 노드에서 두 번 연속 실행해 확인해야 한다.

## 운영 안전성

Driver 설치/업그레이드, initramfs 갱신, Docker/containerd 재시작, Slurm daemon 재시작은 서비스 중단을 일으킬 수 있다. Role은 커널 모듈을 강제로 reload하지 않는다.

Driver 변경이 감지되면 `gpu_reboot_required: true`를 설정한다. `gpu_allow_reboot: false`인 기본 상태에서는 경고만 출력하고 Driver 의존 검증은 다음 실행까지 연기한다. 자동 재부팅은 명시적으로 허용한 경우에만 수행한다. Kubernetes Node drain, Slurm Node drain과 GPU workload 종료를 먼저 수행해야 한다.
