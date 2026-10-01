# Kubernetes / Slurm 상세 설정

노드 구성, 전제조건과 Playbook 실행 순서는 프로젝트 [README](../README.md)를
참고한다. 이 문서는 Kubernetes와 Slurm의 동작 방식 및 상세 변수만 설명한다.

## Kubernetes

`kubernetes_common`이 모든 노드에 kernel/sysctl, containerd, kubelet, kubeadm과
kubectl을 구성한다. Inventory의 첫 `kubernetes_control_plane` 호스트가
`kubeadm init`을 실행하고, 나머지 control-plane과 worker는 동적으로 생성한 token으로
가입한다.

- 기본 저장소: Kubernetes `1.36` minor
- 기본 CNI: Calico `v3.32.2`
- 설치한 Kubernetes 패키지는 자동 업그레이드를 막기 위해 hold
- `/etc/kubernetes/admin.conf`와 `/etc/kubernetes/kubelet.conf`로 기존 가입 상태 판정
- 기존 클러스터는 자동으로 reset하지 않음
- 다중 control-plane은 외부 load balancer 또는 stable DNS endpoint 필요

Primary control-plane에는 기본적으로 `k8suser` 계정과 kubeconfig를 구성하고
`test/kubernetes` 파일을 `~/kubernetes-tests`에 배포한다.
`kubernetes_copy_test_files: false`로 테스트 파일 배포를 끌 수 있다.

### 주요 변수

| 변수 | 기본값 | 설명 |
|---|---|---|
| `kubernetes_repository_minor` | `1.36` | `pkgs.k8s.io` minor 저장소 |
| `kubernetes_package_version` | `""` | 빈 값이면 저장소 최신 patch 사용 |
| `kubernetes_pod_subnet` | `192.168.0.0/16` | Pod CIDR |
| `kubernetes_service_subnet` | `10.96.0.0/12` | Service CIDR |
| `kubernetes_control_plane_endpoint` | `""` | 다중 control-plane의 stable endpoint |
| `kubernetes_node_ip` | 자동 | multi-NIC 환경에서 host별 지정 |
| `kubernetes_node_name` | VM short hostname | Kubernetes에 등록할 Node 이름 |
| `kubernetes_install_cni` | `true` | Primary control-plane에서 CNI 적용 |
| `kubernetes_cni_manifest_url` | Calico 고정 URL | 사용할 CNI manifest |
| `kubernetes_manage_admin_user` | `true` | 관리자 사용자와 그룹 관리 |
| `kubernetes_admin_user` | `k8suser` | kubeconfig와 테스트 파일 사용자 |
| `kubernetes_admin_uid` / `gid` | `2001` | 모든 control-plane의 고정 UID/GID |
| `kubernetes_admin_home` | `/home/k8suser` | 관리자 사용자 홈 |

`--limit`으로 worker만 구성하려면 Primary control-plane이 이미 구성되어 있고 Ansible로
접근 가능해야 한다.

## Slurm

`slurm_common`이 모든 노드에 Slurm, MUNGE, chrony와 동일한 `slurm.conf`를
구성한다. Controller의 MUNGE key를 compute 노드에 배포하며, 작업 사용자의
사용자명·UID/GID·홈 경로가 모든 노드에서 같은지 적용 전에 검증한다.

### 작업 사용자와 NFS

- 기본 작업 사용자: `slurmuser` (`2000:2000`)
- 기본 NFS 경로: `/mnt/slurm`
- 테스트 스크립트: `/mnt/slurm/scripts`
- batch 출력: `/mnt/slurm/outputs`
- NFS는 Playbook 실행 시 mount하지만 `/etc/fstab`에는 등록하지 않음
- `slurm_copy_test_files: false`로 테스트 파일 배포 비활성화 가능

### Accounting

`slurm_accounting_enabled: true`이면 Controller VM에 MariaDB와 SlurmDBD를 구성한다.
MariaDB 사용자는 로컬 Unix socket으로 인증하며 DB 데이터는 Controller의 로컬
디스크에 저장한다. 기본 cluster `compute-cluster`, account `compute`와 `slurmuser`
association을 생성한다.

### Compute 노드 자원

운영 환경에서는 `slurmd -C` 결과를 기준으로 CPU와 메모리를 명시하는 것을 권장한다.
값을 생략하면 Ansible facts를 사용하며 메모리는 OS 여유 공간을 위해 총량의 95%로
계산한다.

```yaml
slurm-compute-01:
  ansible_host: 192.0.2.21
  slurm_node_name: compute01
  slurm_cpus: 64
  slurm_real_memory: 240000
  slurm_gres: gpu:a100:4
```

GPU compute는 `slurm_compute`와 `slurm_gpu_compute` 양쪽에 같은 inventory hostname으로
등록한다. GPU node setup이 Driver/CUDA를 준비하고, GPU cluster setup이 `gres.conf`와
공통 `slurm.conf`에 GPU 자원을 반영한다.

### 주요 변수

| 변수 | 기본값 | 설명 |
|---|---|---|
| `slurm_cluster_name` | `compute-cluster` | 클러스터 이름 |
| `slurm_partition_name` | `compute` | 기본 partition |
| `slurm_restart_services` | `true` | 설정 변경 시 daemon 재시작 |
| `slurm_extra_config` | `""` | `slurm.conf` 추가 설정 |
| `slurm_accounting_enabled` | `true` | MariaDB/SlurmDBD 구성 |
| `slurm_accounting_host` | Controller 주소 | SlurmDBD 연결 주소 |
| `slurm_accounting_account` | `compute` | 작업 사용자의 기본 account |
| `slurm_accounting_db_name` | `slurm_acct_db` | MariaDB database 이름 |
| `slurm_accounting_db_user` | `slurm` | Unix socket 인증 DB 사용자 |
| `slurm_jobacct_gather_type` | `jobacct_gather/linux` | Job resource accounting 방식 |
| `slurm_manage_test_user` | `true` | 작업 사용자와 그룹 관리 |
| `slurm_test_user` | `slurmuser` | 작업 사용자 이름 |
| `slurm_test_uid` / `gid` | `2000` | 모든 Slurm 노드의 고정 UID/GID |
| `slurm_nfs_source` | `""` | NFS `server:/export` |
| `slurm_nfs_dest` | `/mnt/slurm` | NFS mount 위치 |
| `slurm_scripts_dir` | `/mnt/slurm/scripts` | 테스트 스크립트 디렉터리 |
| `slurm_outputs_dir` | `/mnt/slurm/outputs` | batch 출력 디렉터리 |

배포판 Slurm의 cgroup v2 지원 차이를 고려해 기본값은 `proctrack/linuxproc`와
`task/affinity`다. 대상 버전에서 검증한 뒤 cgroup plugin과 `cgroup.conf` 관리를
활성화한다. 모든 Slurm 노드는 같은 저장소와 패키지 버전을 사용해야 한다.

테스트 절차는 [Kubernetes 테스트](../test/kubernetes/README.md)와
[Slurm 테스트](../test/slurm/README.md)를 참고한다.
