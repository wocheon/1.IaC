# kubernetes_common

Ubuntu 노드에 Kubernetes용 kernel/sysctl, containerd, kubelet, kubeadm, kubectl을 설치한다. `kubernetes_control_plane`과 `kubernetes_worker`가 내부 호출하며 클러스터 init/join은 수행하지 않는다.
