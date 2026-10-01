# Kubernetes 테스트 파일

테스트는 control-plane에서 Kubernetes 관리자 사용자 `k8suser`로 실행한다.
파일은 `/home/k8suser/kubernetes-tests`에 배포되고 kubeconfig는
`/home/k8suser/.kube/config`를 사용한다.

```bash
sudo -iu k8suser
cd ~/kubernetes-tests
kubectl get nodes -o wide
```

현재 테스트 구성은 control-plane 1대와 worker 2대 이상을 전제로 한다.

## add_node_labels.sh

테스트 manifest가 각 노드를 선택할 수 있도록 라벨을 추가한다.

```bash
./add_node_labels.sh
kubectl get nodes --show-labels
```

- 모든 노드: `deploy-test=node-1`, `node-2`, `node-3` 순서로 지정
- worker 노드: `test-node=worker-01`, `worker-02` 순서로 지정

테스트가 끝난 뒤 라벨만 제거할 때는 다음 명령을 사용한다.

```bash
./add_node_labels.sh cleanup
```

## control_plane_check.yaml

control-plane 1대와 worker 2대에 nginx Pod를 하나씩 배치해 각 노드의
스케줄링 상태를 확인한다. 먼저 노드 라벨을 적용해야 한다.

```bash
./add_node_labels.sh
kubectl apply -f control_plane_check.yaml
kubectl get pods -o wide
```

`nginx-node-1`, `nginx-node-2`, `nginx-node-3` Pod의 `NODE` 열이 서로 다른
노드를 가리키는지 확인한다.

kubeadm의 control-plane 노드에는 기본적으로 `NoSchedule` taint가 있으므로
`nginx-node-1`이 `Pending`일 수 있다. 이 경우 다음 명령으로 원인을 확인한다.

```bash
kubectl describe pod -l app=nginx-node-1
kubectl describe node -l node-role.kubernetes.io/control-plane
```

## nginx-node-test.yaml

worker 2대에 서로 다른 nginx 페이지를 배포하고 NodePort로 접근되는지
확인한다. 먼저 worker 라벨을 적용해야 한다.

```bash
./add_node_labels.sh
kubectl apply -f nginx-node-test.yaml
kubectl get pods -o wide
kubectl get services
```

- `nginx-worker-01`: `test-node=worker-01`, NodePort `30081`
- `nginx-worker-02`: `test-node=worker-02`, NodePort `30082`

브라우저나 `curl`로 Kubernetes 노드 IP의 NodePort에 접속한다.

```bash
curl http://<node-ip>:30081
curl http://<node-ip>:30082
```

각 응답에서 `Hello from Worker 01`, `Hello from Worker 02`가 표시되는지
확인한다.

## gpu-pod-test.yaml

GPU 1개를 요청하고 계속 점유하는 Pod를 실행해 할당된 노드와 `nvidia-smi` 결과를
확인한다. GPU worker에 NVIDIA 드라이버, NVIDIA Container Toolkit과
Kubernetes NVIDIA device plugin이 먼저 구성되어 있어야 한다.
`playbooks/k8s_gpu_node_setup.yaml`로 GPU host를 먼저 준비한 뒤
`playbooks/k8s_cluster_setup.yaml`로 Kubernetes를 구성하고,
`playbooks/k8s_gpu_cluster_setup.yaml`로 runtime과 Device Plugin을 연결한다.
`kubernetes_set_nvidia_default_runtime: false`인 경우 Pod spec에
`runtimeClassName: nvidia`를 추가한다.

테스트 이미지는 공통 CUDA 12.6 설정에 맞춘
`nvidia/cuda:12.6.3-base-ubuntu24.04`다.

```bash
kubectl apply -f gpu-pod-test.yaml
kubectl get pod nvidia-gpu-test -o wide
kubectl logs nvidia-gpu-test
```

정상 실행되면 Pod가 GPU worker에서 `Running` 상태를 유지하고 로그에 노드 이름과
GPU 정보가 표시된다. GPU는 Pod를 삭제할 때 반환된다. `Pending` 상태라면 GPU
리소스 등록 여부와 이벤트를 확인한다.

```bash
kubectl get nodes -o 'custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu'
kubectl describe pod nvidia-gpu-test
```

## 테스트 정리

생성한 Deployment, Service, ConfigMap과 테스트용 노드 라벨을 제거한다.

```bash
kubectl delete -f control_plane_check.yaml --ignore-not-found
kubectl delete -f nginx-node-test.yaml --ignore-not-found
kubectl delete -f gpu-pod-test.yaml --ignore-not-found
./add_node_labels.sh cleanup
```

## 현재 배포 설정

- 관리자 사용자: `k8suser` (`UID:GID` = `2001:2001`)
- 클러스터 이름: `kubernetes`
- 테스트 경로: `/home/k8suser/kubernetes-tests`
- Pod CIDR: `192.168.0.0/16`
- Service CIDR: `10.96.0.0/12`
