# kubernetes_worker

최초 control-plane에서 단기 join token을 발급해 아직 가입하지 않은 worker를 클러스터에 추가한다. `/etc/kubernetes/kubelet.conf`가 있으면 join을 건너뛴다.

