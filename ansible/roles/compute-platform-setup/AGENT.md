# Compute Platform Ansible 작업 지침

일반/GPU Kubernetes, 일반/GPU Slurm, standalone GPU VM, Docker GPU host를
하나의 inventory와 독립된 플랫폼 playbook으로 관리한다.

- `gpu_common`은 Driver/CUDA/Container Toolkit 공유 구현이다. 환경 Role이 include_role로 호출한다.
- `k8s_gpu_node_setup`은 Driver/Toolkit 사전 준비만 담당한다. `k8s_cluster_setup`으로 기본 클러스터를 구성한 뒤 별도 playbook/Role인 `k8s_gpu_cluster_setup`이 runtime/device plugin을 연결한다.
- `slurm_gpu_node_setup`은 Driver/CUDA 사전 준비만 담당한다. `slurm_common/controller/compute`로 기본 클러스터를 구성한 뒤 `slurm_gpu_cluster_setup`이 GRES와 GPU 자원을 연결한다.
- `gpu_standalone`, `gpu_docker`는 독립 VM 환경이다.
- Kubernetes GPU worker는 같은 inventory hostname으로 `kubernetes_workers`와
  `kubernetes_gpu_workers` 양쪽에 등록한다. Slurm GPU compute도 같은 hostname을
  `slurm_compute`와 `slurm_gpu_compute` 양쪽에 등록한다.
- Kubernetes와 Docker는 host CUDA/cuDNN을 설치하지 않는다.
- GPU Operator가 driver/runtime을 관리하면 k8s_gpu_node_setup Role을 중복 적용하지 않는다.
- 자동 reboot와 Slurm cgroup 관리의 기본값은 false다. 재부팅이 필요하면 GPU cluster 등록 전에 중단한다.
- Slurm은 slurm_gpu_node_setup.yaml → slurm_cluster_setup.yaml → slurm_gpu_cluster_setup.yaml 순서로 구성한다.
- kubeadm PKI, 기존 MUNGE 키, MariaDB 데이터는 재생성하지 않는다.
- k8suser 2001:2001, slurmuser 2000:2000과 기존 NFS/Accounting 설정을 보존한다.
- shell보다 기본 모듈을 우선하고 command는 상태 검사와 changed_when으로 멱등성을 보호한다.
- 플랫폼별 playbook은 독립 실행하며, 실제 호스트를 변경하는 검증은 사용자 요청 시 수행한다.

검증: 전체/플랫폼별 syntax-check, CPU/GPU inventory의 host 선택, 공통 템플릿 렌더링,
GPU/CPU 역할 분기와 복사 경로를 확인한다. ansible-lint가 있으면 실행한다.
실제 VM에서 최초 배포와 재실행 changed=0 검증은 별도로 수행한다.
