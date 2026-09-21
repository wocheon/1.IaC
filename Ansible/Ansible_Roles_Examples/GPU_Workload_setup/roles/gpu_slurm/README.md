# gpu_slurm

기존 Slurm Compute Node에 NVIDIA Driver, CUDA Toolkit과 GPU GRES 설정을 추가한다. Slurm 자체와 Controller는 설치하거나 구성하지 않는다.

```yaml
- hosts: gpu_compute_nodes
  become: true
  roles:
    - role: gpu_slurm
      vars:
        slurm_gres_autodetect: nvml
```

`gres.conf`은 기본적으로 관리하지만 `cgroup.conf`과 `slurmd` 재시작은 기존 운영 설정 보호를 위해 기본 비활성이다. Controller의 `slurm.conf`에는 별도로 `GresTypes=gpu`와 Node의 `Gres`를 설정해야 한다.

Host DCGM은 `gpu_install_dcgm: true`일 때만 설치한다. `dcgm_run_diagnostics`는 기본 비활성이며 Slurm Node를 drain하고 실행 중인 Job이 없는 상태에서만 활성화해야 한다.
