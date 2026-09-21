# Kubernetes / Slurm Cluster Ansible Roles

Ubuntu 서버에 서로 독립된 Kubernetes 클러스터와 Slurm 클러스터를 구성한다. 기존 `GPU_Workload_settings`와 같은 방식으로 `inventory`, `playbooks`, `roles`를 분리했으며, GPU 호스트 설정은 이 저장소의 범위가 아니다.

## 구조

```text
inventory/
├── group_vars/all.yaml
└── inventory.example.yaml
playbooks/main.yaml
roles/
├── kubernetes_common/
├── kubernetes_control_plane/
├── kubernetes_worker/
├── slurm_common/
├── slurm_controller/
└── slurm_compute/
```

| Role | 책임 |
|---|---|
| `kubernetes_common` | kernel/sysctl, swap, containerd, kubelet/kubeadm/kubectl |
| `kubernetes_control_plane` | 최초 `kubeadm init`, 추가 control-plane join, 관리자 kubeconfig, CNI |
| `kubernetes_worker` | token을 동적으로 발급해 worker join |
| `slurm_common` | Slurm/MUNGE/chrony, 공유 MUNGE 키, 공통 `slurm.conf` |
| `slurm_controller` | controller 초기화와 `slurmctld` |
| `slurm_compute` | compute node 초기화와 `slurmd` |

## 지원 범위

- Ubuntu 22.04/24.04
- x86_64, aarch64
- kubeadm 기반 Kubernetes, containerd runtime
- 단일 control-plane 또는 외부 load balancer를 사용한 다중 control-plane
- 단일 Slurm controller와 1대 이상의 compute node
- MUNGE 인증 및 기본 `select/cons_tres`, CPU affinity 설정

다음 항목은 별도 인프라/운영 절차가 필요하다.

- load balancer, DNS, 방화벽과 보안 그룹
- Kubernetes ingress, storage class, metrics, GPU device plugin
- Kubernetes/Slurm 버전 업그레이드와 기존 클러스터 reset
- SlurmDBD, 회계 DB, HA controller, LDAP/NSS 사용자 동기화
- NVIDIA driver, CUDA, GRES 자동 감지

Slurm은 모든 노드에서 동일한 UID/GID 사용자 공간과 동기화된 시간이 필요하다. 이 Role은 `chrony`를 활성화하지만 NTP 서버와 LDAP/NSS 자체는 구성하지 않는다.

## 빠른 시작

Ansible control node에 `ansible-core`가 필요하다.

```bash
cp inventory/inventory.example.yaml inventory/inventory.yaml
# inventory/inventory.yaml과 inventory/group_vars/all.yaml 수정
ansible-playbook --syntax-check playbooks/main.yaml
ansible-playbook playbooks/main.yaml
```

특정 클러스터만 구성할 수 있다.

```bash
ansible-playbook playbooks/main.yaml --tags kubernetes
ansible-playbook playbooks/main.yaml --tags slurm
ansible-playbook playbooks/main.yaml --limit kubernetes_workers
```

`--limit`로 join Role만 실행할 때도 최초 control-plane이 이미 구성되어 있고 Ansible로 접근 가능해야 한다.

WSL의 `/mnt/c`처럼 디렉토리가 world-writable로 보이면 Ansible이 보안상 `ansible.cfg` 자동 탐색을 무시할 수 있다. 그 경우 `ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook ...`처럼 설정 파일을 명시하거나 Linux 파일시스템에서 실행한다.

## Kubernetes 설정

기본값은 Kubernetes `1.36` minor 저장소와 Calico `v3.32.2` manifest다. minor 저장소는 패키지 버전 범위를 결정하고, 실제 설치된 kubeadm patch 버전을 `kubeadm init`에 사용한다. 패키지는 자동 업그레이드를 막기 위해 hold된다.

중요 변수:

| 변수 | 기본값 | 설명 |
|---|---|---|
| `kubernetes_repository_minor` | `1.36` | `pkgs.k8s.io` minor 저장소 |
| `kubernetes_package_version` | `""` | 빈 값은 저장소 최신 patch, 값 지정 시 세 패키지 고정 |
| `kubernetes_pod_subnet` | `192.168.0.0/16` | Pod CIDR |
| `kubernetes_service_subnet` | `10.96.0.0/12` | Service CIDR |
| `kubernetes_control_plane_endpoint` | `""` | HA endpoint. 예: `k8s-api.example.com:6443` |
| `kubernetes_node_ip` | 자동 | multi-NIC이면 host별 명시 |
| `kubernetes_install_cni` | `true` | 최초 control-plane에서 CNI 적용 |
| `kubernetes_cni_manifest_url` | Calico 고정 URL | 검토 후 조직 내부 URL로 변경 가능 |
| `kubernetes_admin_user` | `ansible_user` | `$HOME/.kube/config`을 받을 사용자 |

control-plane이 둘 이상이면 `kubernetes_control_plane_endpoint`가 필수다. load balancer는 API server port로 모든 control-plane을 전달하도록 Ansible 실행 전에 준비한다.

Role은 `/etc/kubernetes/admin.conf`와 `/etc/kubernetes/kubelet.conf` 존재 여부로 초기화/가입 상태를 판정한다. 기존 클러스터를 자동 reset하지 않는다.

## Slurm 설정

controller가 가진 `/etc/munge/munge.key`를 compute 노드에 안전하게 전달하고, Inventory와 gathered facts를 바탕으로 모든 노드에 동일한 `slurm.conf`를 만든다.

compute 노드별 권장 변수:

```yaml
slurm-compute-01:
  ansible_host: 192.0.2.21
  slurm_node_name: compute01
  slurm_cpus: 64
  slurm_real_memory: 240000
  slurm_gres: gpu:a100:4
```

`slurm_cpus`와 `slurm_real_memory`를 생략하면 Ansible facts를 사용하며 메모리는 OS 여유 공간을 위해 총량의 95%로 계산한다. 실제 운영에서는 `slurmd -C` 결과에 맞춰 명시하는 편이 안전하다. `slurm_gres`를 설정했다면 GPU 노드의 `gres.conf`와 NVIDIA 환경은 별도로 구성해야 한다.

중요 변수:

| 변수 | 기본값 | 설명 |
|---|---|---|
| `slurm_cluster_name` | `compute-cluster` | 클러스터 이름 |
| `slurm_partition_name` | `compute` | 기본 partition |
| `slurm_restart_services` | `true` | 설정 변경 시 daemon 재시작 |
| `slurm_extra_config` | `""` | `slurm.conf` 끝에 추가할 고급 설정 |

배포판 Slurm 버전마다 cgroup v2 지원 수준이 다르므로 기본값은 `proctrack/linuxproc`와 `task/affinity`다. 대상 버전에서 검증한 뒤 `slurm_proctrack_type: proctrack/cgroup`, `slurm_task_plugin: task/affinity,task/cgroup`으로 변경하고 필요하면 `slurm_extra_config`와 `cgroup.conf` 관리를 확장한다.

배포판 `slurm-wlm` 패키지를 사용하므로 모든 노드가 같은 Ubuntu 저장소와 패키지 버전을 사용해야 한다. 대규모/운영 환경에서는 SchedMD 권고에 따라 자체 빌드한 동일 DEB 패키지를 공급하는 방식을 검토한다.

## 검증

```bash
# Kubernetes control-plane
kubectl get nodes -o wide
kubectl get pods -A

# Slurm controller
scontrol ping
sinfo -Nel

# 각 Slurm 노드
munge -n | unmunge
systemctl status munge slurmctld  # controller
systemctl status munge slurmd     # compute
```

최초 검증은 빈 VM에서 수행하고, 같은 playbook을 다시 실행해 의도하지 않은 변경이 없는지 확인한다. containerd 재시작, control-plane 추가, Slurm 설정 변경은 실행 중 workload에 영향을 줄 수 있다.

## 참고 문서

- Kubernetes kubeadm 설치: <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/>
- Kubernetes cluster 생성: <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/>
- Kubernetes container runtime: <https://kubernetes.io/docs/setup/production-environment/container-runtimes/>
- Slurm 관리자 Quick Start: <https://slurm.schedmd.com/quickstart_admin.html>
- Slurm `slurm.conf`: <https://slurm.schedmd.com/slurm.conf.html>
