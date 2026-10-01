# Compute Platform Setup

기존 Ubuntu VM에 Kubernetes, Slurm, Standalone GPU 또는 Docker GPU 환경을
구성하는 Ansible 프로젝트다. VM, 네트워크, 디스크와 GPU 같은 인프라는 생성하지
않으며 Terraform 등으로 준비된 호스트를 대상으로 한다.

## 노드 유형별 설치 구성

`O`는 기본 설치, `선택`은 변수로 활성화하는 항목, `X`는 해당 노드에 설치하지
않는 항목이다.

| 노드 유형 | NVIDIA Driver | Host CUDA | Host cuDNN | Container 구성 | 주요 플랫폼 구성 |
|---|:---:|:---:|:---:|---|---|
| Kubernetes Control-plane | X | X | X | containerd | kubelet, kubeadm, kubectl, CNI, 관리자 kubeconfig |
| Kubernetes 일반 Worker | X | X | X | containerd | kubelet, kubeadm, kubectl, worker join |
| Kubernetes GPU Worker | O\* | X | X | containerd, NVIDIA Container Toolkit | 일반 Worker 구성, NVIDIA runtime, Device Plugin, `nvidia.com/gpu` |
| Slurm Controller | X | X | X | X | Slurm, MUNGE, chrony, `slurmctld`, 선택적 NFS·MariaDB·SlurmDBD |
| Slurm 일반 Compute | X | X | X | X | Slurm, MUNGE, chrony, `slurmd`, 선택적 NFS |
| Slurm GPU Compute | O | O | 선택 | X | 일반 Compute 구성, GRES, 선택적 cgroup·DCGM |
| Standalone GPU | O | O | 선택 | X | Python virtualenv, PyTorch, 선택적 TensorFlow·DCGM |
| Docker GPU | O | X | X | Docker Engine, NVIDIA Container Toolkit | NVIDIA Docker runtime, 선택적 DCGM Exporter |

\* `kubernetes_gpu_driver_managed: true`이면 Kubernetes GPU Worker의 Driver 설치를
건너뛴다. Kubernetes와 Docker의 CUDA userspace는 컨테이너 이미지가 제공한다.

## 환경별 노드 배치와 실행 순서

각 Playbook은 독립적으로 실행한다. GPU 클러스터는 노드 준비, 기본 클러스터,
GPU 연동 단계를 순서대로 적용한다.

| 환경 | 필요한 노드와 Inventory | Playbook 실행 순서 |
|---|---|---|
| Kubernetes CPU | control-plane 1대 이상은 `kubernetes_control_plane`, worker 1대 이상은 `kubernetes_workers` | `k8s_cluster_setup.yaml` |
| Kubernetes GPU | 모든 worker는 `kubernetes_workers`, GPU worker는 같은 hostname을 `kubernetes_gpu_workers`에도 등록 | `k8s_gpu_node_setup.yaml` → 필요 시 재부팅·재실행 → `k8s_cluster_setup.yaml` → `k8s_gpu_cluster_setup.yaml` |
| Slurm CPU | controller 정확히 1대는 `slurm_controllers`, compute 1대 이상은 `slurm_compute` | `slurm_cluster_setup.yaml` |
| Slurm GPU | 모든 compute는 `slurm_compute`, GPU compute는 같은 hostname을 `slurm_gpu_compute`에도 등록 | `slurm_gpu_node_setup.yaml` → 필요 시 재부팅·재실행 → `slurm_cluster_setup.yaml` → `slurm_gpu_cluster_setup.yaml` |
| Standalone GPU | 독립 GPU VM을 `gpu_standalone_nodes`에 등록 | `standalone_gpu_node_setup.yaml` |
| Docker GPU | 독립 GPU VM을 `gpu_docker_nodes`에 등록 | `docker_gpu_node_setup.yaml` |

## 빠른 시작

`inventory/inventory.example.yaml`을 참고해 `inventory/inventory.yaml`과
`inventory/group_vars/all.yaml`을 환경에 맞게 수정한다.

```bash
cd ansible/compute_platform_setup
ansible-inventory --graph
```

Kubernetes GPU 클러스터 예시는 다음과 같다.

```bash
ansible-playbook playbooks/k8s_gpu_node_setup.yaml
# 재부팅 안내가 나오면 노드를 재부팅하고 같은 Playbook을 다시 실행한다.
ansible-playbook playbooks/k8s_cluster_setup.yaml
ansible-playbook playbooks/k8s_gpu_cluster_setup.yaml
```

GCE hostname이 FQDN이면 클러스터 구성 전에 VM short hostname으로 정규화할 수 있다.

```bash
ansible-playbook playbooks/set_hostname.yaml
```

## 공통 전제조건

- Ansible control node에 `ansible-core`가 설치되어 있어야 한다.
- 대상 VM은 inventory 주소로 SSH 접속할 수 있어야 하며, 접속 계정은
  `become: true`로 root 권한을 얻을 수 있어야 한다.
- 대상 VM에 `/usr/bin/python3`가 있어야 한다.
- Ubuntu, Kubernetes, NVIDIA, Docker 저장소와 GitHub/PyPI 등에 대한 outbound
  HTTPS가 필요하다. 폐쇄망에서는 내부 mirror와 URL 변수 재정의가 필요하다.
- VM은 고유하고 안정적인 hostname과 IP를 가져야 한다. 클러스터 간 통신에 필요한
  Kubernetes, Slurm, NFS 포트는 방화벽에서 허용해야 한다.
- Role은 VM·VPC·방화벽·load balancer·DNS·NFS server를 생성하거나 디스크를
  증설하지 않는다.
- CPU, 메모리와 디스크는 workload, 컨테이너 이미지, 로그, Slurm job 및 Accounting
  DB 증가량을 고려해 미리 준비한다. GPU Role은 root filesystem 여유 공간 10 GiB를
  기본 권장값으로 점검한다.
- 기존 클러스터 reset이나 데이터 이전은 수행하지 않는다. 기존 설정에 적용할 때는
  kubeadm PKI, MUNGE key, MariaDB 데이터와 서비스 중단 영향을 먼저 확인한다.

## Inventory 규칙과 노드 이름

GPU 노드는 기본 worker/compute 그룹과 GPU 그룹 양쪽에 **같은 inventory hostname**으로
등록한다. 예시는 [inventory.example.yaml](inventory/inventory.example.yaml)을 참고한다.

Kubernetes Node 이름은 GCE VM short hostname을 사용한다. Inventory 별칭은 SSH 접속과
그룹 구분에만 사용되며 `kubectl get nodes`의 이름을 변경하지 않는다. 별도 이름이
필요한 경우 host 변수 `kubernetes_node_name`을 클러스터 최초 구성 전에 지정한다.
이미 가입한 Kubernetes Node의 이름 변경은 reset/rejoin이 필요하므로 Role이 자동으로
수행하지 않는다.

## Role별 전제조건과 주요 구성

`(내부)` Role은 상위 Role이 호출하므로 일반적으로 직접 실행하지 않는다.

### Kubernetes

| Role | 사용 전제조건 | 주요 구성 |
|---|---|---|
| `kubernetes_common` (내부) | Ubuntu 22.04 이상, `x86_64`/`aarch64`, `overlay`·`br_netfilter` 사용 가능 | containerd, kubelet, kubeadm, kubectl, kernel/sysctl |
| `kubernetes_control_plane` | 고정 IP, API/CNI 통신, 다중 control-plane은 stable endpoint 필요 | kubeadm control-plane, CNI, 관리자 kubeconfig |
| `kubernetes_worker` | 최초 control-plane 완료, API/CNI 통신 가능 | kubeadm worker join, kubelet |
| `k8s_gpu_node_setup` | NVIDIA GPU, 호환 커널, GPU Operator와 관리 범위 비중복 | NVIDIA Driver, Container Toolkit 패키지 |
| `k8s_gpu_cluster_setup` | GPU node setup과 worker join 완료, containerd 설치 | containerd NVIDIA runtime, GPU label, NVIDIA Device Plugin |

### Slurm

| Role | 사용 전제조건 | 주요 구성 |
|---|---|---|
| `slurm_common` (내부) | Ubuntu 22.04 이상, controller 1대, compute 1대 이상, 동일한 작업 사용자 UID/GID | Slurm, MUNGE, chrony, 공통 `slurm.conf`, 선택적 NFS mount |
| `slurm_controller` | state/log 공간, Accounting 사용 시 DB 공간과 6819 포트 | `slurmctld`, 선택적 MariaDB·SlurmDBD |
| `slurm_compute` | controller 통신, MUNGE와 공통 설정 공유 | `slurmd`, 노드 CPU·메모리 등록 |
| `slurm_gpu_node_setup` | NVIDIA GPU, 호환 커널, 작업 중단 후 Driver/DCGM 적용 | NVIDIA Driver, CUDA Toolkit, 선택적 DCGM |
| `slurm_gpu_cluster_setup` | GPU node setup과 Slurm cluster 완료 | GRES, 선택적 cgroup, `slurm.conf` GPU 자원 |

### 공통 및 독립 GPU

| Role | 사용 전제조건 | 주요 구성 |
|---|---|---|
| `gpu_common` (내부) | Ubuntu 20.04/22.04/24.04, `x86_64`/`aarch64`, Driver용 커널 패키지 | GPU preflight, Driver, CUDA, cuDNN, Container Toolkit 선택 구성 |
| `gpu_standalone` | CUDA와 Python wheel 공간, NVIDIA/PyPI 접근 | Driver, CUDA, Python virtualenv, PyTorch, 선택적 TensorFlow·cuDNN·DCGM |
| `gpu_docker` | Docker 이미지/volume 공간, Docker 재시작 허용 | Driver, Docker Engine, Container Toolkit, NVIDIA runtime, 선택적 DCGM Exporter |

## 주요 GPU 변수

운영 시 주로 변경하는 값은 [inventory/group_vars/all.yaml](inventory/group_vars/all.yaml)에
모여 있다. 빈 버전 값은 저장소가 제공하는 버전이나 자동 감지 결과를 사용한다.

| 변수 | 기본값 | 설명 |
|---|---|---|
| `gpu_install_driver` | `true` | 해당 환경에서 NVIDIA Driver 설치 |
| `nvidia_driver_version` | `""` | Driver branch. 빈 값이면 자동 감지 |
| `nvidia_driver_flavor` | `""` | proprietary 또는 `-open` |
| `nvidia_driver_source` | `distro` | `distro` 또는 `cuda_repo` |
| `gpu_install_cuda` | Role별 상이 | 호스트 CUDA Toolkit 설치 |
| `cuda_version` | `12.6` | CUDA Toolkit 버전 |
| `gpu_install_cudnn` | `false` | 호스트 cuDNN 설치 |
| `gpu_allow_reboot` | `false` | Driver 변경 후 자동 재부팅 허용 |
| `gpu_preflight_enabled` | `true` | 설치 전 GPU·커널·디스크 점검 |
| `gpu_install_dcgm` | `false` | Standalone/Slurm Host DCGM 설치 |
| `gpu_install_dcgm_exporter` | `false` | Docker DCGM Exporter 실행 |

Role 기본값과 별개로 현재 `inventory/group_vars/all.yaml`은 GCP 커널용
`580-open` Driver와 `distro` 저장소를 명시한다.

## 운영 시 주의사항

- `gpu_allow_reboot`의 기본값은 `false`다. Driver 변경으로 재부팅이 필요하면 GPU
  cluster 연동 전에 중단하며, 재부팅 후 같은 node setup Playbook을 다시 실행한다.
- Kubernetes와 Docker GPU 구성은 호스트 CUDA/cuDNN을 설치하지 않는다. CUDA
  userspace는 컨테이너 이미지가 제공한다.
- Driver, CUDA, cuDNN과 프레임워크의 전체 호환성 조합은 Role이 보장하지 않는다.
  운영 환경은 NVIDIA와 프레임워크 지원표를 확인하고 버전을 고정한다.
- GPU preflight는 Secure Boot, kernel headers, nouveau/NVIDIA module, 기존 Driver,
  device node, root filesystem과 CUDA/Driver 최소 조건을 점검한다.
- Kubernetes GPU runtime은 import된 drop-in을 포함한 `containerd config dump`의
  유효 설정으로 확인한다. runtime 변경 시 containerd 재시작 전에 노드를 drain한다.
- GPU Operator가 Driver/runtime을 관리하면 `kubernetes_gpu_enabled: false`, Device
  Plugin만 외부에서 관리하면 `kubernetes_gpu_install_device_plugin: false`를 사용한다.
- Slurm의 NVML plugin을 사용할 수 없으면 `slurm_gres_autodetect: "off"`와 host별
  `slurm_gpu_type`, `slurm_gpu_count`를 지정한다. cgroup 장치 격리는 기본 비활성이다.
- `docker_manage_daemon_json: true`이면 Role이 `/etc/docker/daemon.json` 전체를 관리한다.
- DCGM 진단, containerd/Docker 재시작과 GPU 설정 재적용 전에는 실행 중인 workload를
  종료하거나 Kubernetes/Slurm 노드를 drain한다.

### NVIDIA Driver 설치 실패 복구

Driver 버전을 명시하지 않으면 `ubuntu-drivers list --gpgpu` 결과를 사용하고, 명시한
버전은 자동 감지보다 우선한다. GCP 커널에서는 DKMS 빌드보다 현재 커널용
`linux-modules-nvidia-<branch>-open-gcp` 패키지를 우선 사용한다.

기존 Driver 패키지가 미구성 상태라면 먼저 `nvidia_driver_version`,
`nvidia_driver_source`, `nvidia_driver_flavor`를 호환되는 값으로 수정한 뒤 패키지를
복구한다. 설정을 바꾸지 않고 `apt --fix-broken install`만 실행하면 같은 DKMS 빌드가
반복될 수 있다.

```bash
sudo grep -nE 'error:|fatal:' /var/lib/dkms/nvidia/*/build/make.log | tail -50
sudo apt --fix-broken install
dkms status
dpkg --audit
nvidia-smi
```

## 설정과 상세 문서

- 공통 운영 변수: [inventory/group_vars/all.yaml](inventory/group_vars/all.yaml)
- Kubernetes·Slurm 상세 구성: [docs/clusters.md](docs/clusters.md)

## 테스트

| 환경 | 테스트 문서/스크립트 |
|---|---|
| Kubernetes | [test/kubernetes/README.md](test/kubernetes/README.md) |
| Slurm | [test/slurm/README.md](test/slurm/README.md) |
| Standalone GPU | [test/standalone_gpu/run_gpu_test.sh](test/standalone_gpu/run_gpu_test.sh) |
| Docker GPU | [test/docker_gpu/run_gpu_test.sh](test/docker_gpu/run_gpu_test.sh) |

GPU 컨테이너 테스트는 `nvidia/cuda:12.6.3-base-ubuntu24.04` 이미지를 사용한다.
Standalone/Docker 스크립트는 대상 VM에 자동 배포하지 않으므로 해당 VM에서 복사해
실행하거나 동일한 명령을 실행한다.

## 정적 검증

```bash
ansible-inventory --graph
ansible-playbook --syntax-check playbooks/k8s_cluster_setup.yaml
ansible-playbook --syntax-check playbooks/k8s_gpu_cluster_setup.yaml
ansible-playbook --syntax-check playbooks/slurm_cluster_setup.yaml
ansible-playbook --syntax-check playbooks/slurm_gpu_cluster_setup.yaml
```
