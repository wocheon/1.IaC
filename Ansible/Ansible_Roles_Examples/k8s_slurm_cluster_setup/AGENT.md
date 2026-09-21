# Cluster Ansible 작업 지침

Ubuntu 호스트에 Kubernetes와 Slurm 클러스터를 구성한다. 두 클러스터는 독립된 Inventory 그룹과 Role을 사용한다.

## Role 구조

- `kubernetes_common`: containerd, 커널/sysctl, Kubernetes 패키지
- `kubernetes_control_plane`: kubeadm 초기화, 추가 control-plane join, CNI
- `kubernetes_worker`: worker join
- `slurm_common`: Slurm/MUNGE 패키지, 공유 설정과 키
- `slurm_controller`: controller 구성 및 `slurmctld`
- `slurm_compute`: compute node 구성 및 `slurmd`

## 원칙

- Ubuntu 22.04/24.04, x86_64/aarch64를 대상으로 한다.
- 기본 모듈을 우선하고 command 사용 시 `creates`, 상태 검사, `changed_when`으로 멱등성을 보호한다.
- kubeadm PKI, `/etc/kubernetes/admin.conf`, 기존 MUNGE key는 재생성하지 않는다.
- Kubernetes 패키지는 hold하고 업그레이드는 이 프로젝트 범위에서 자동화하지 않는다.
- 다중 control-plane은 안정적인 `kubernetes_control_plane_endpoint`가 있어야 한다.
- Slurm의 모든 노드는 동일한 `munge.key`, `slurm.conf`, 사용자 UID/GID 체계를 사용해야 한다.
- 운영 클러스터에 재적용하기 전 drain, 백업, 버전 업그레이드 절차를 별도로 수행한다.

## 검증

1. `ansible-playbook --syntax-check playbooks/main.yaml`
2. `ansible-lint`가 설치되어 있으면 전체 프로젝트 lint
3. 신규 VM에서 최초 실행 후 동일 명령을 다시 실행하여 `changed=0` 수렴 확인
4. Kubernetes: `kubectl get nodes`, `kubectl get pods -A`
5. Slurm: `scontrol ping`, `sinfo`, `munge -n | unmunge`

