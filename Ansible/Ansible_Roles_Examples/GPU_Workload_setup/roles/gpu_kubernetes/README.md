# gpu_kubernetes

기존 Kubernetes Worker Node의 NVIDIA Driver와 containerd NVIDIA runtime을 구성한다. Kubernetes, kubelet, Device Plugin, GPU Operator는 설치하지 않는다.

```yaml
- hosts: gpu_workers
  become: true
  roles:
    - role: gpu_kubernetes
      vars:
        kubernetes_gpu_driver_managed: false
```

Cloud Provider가 Driver를 관리하면 `kubernetes_gpu_driver_managed: true`로 설정한다. GPU Operator가 Driver와 Container Toolkit 모두를 관리하는 클러스터에서는 이 Role을 적용하지 않는다. containerd 변경은 노드의 Pod에 영향을 주므로 먼저 drain하는 것을 권장한다.

DCGM/DCGM Exporter는 Node Role에서 설치하지 않는다. GPU Operator 또는 DCGM Exporter Helm 배포가 Cluster Layer에서 수명주기를 관리한다.
