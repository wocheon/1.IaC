# kubernetes_control_plane

Inventory의 첫 `kubernetes_control_plane` 호스트를 `kubeadm init`하고 나머지 호스트는 control-plane으로 join한다. 최초 노드에서 CNI와 사용자 kubeconfig를 구성한다. 다중 control-plane에는 외부 stable endpoint가 필수다.

