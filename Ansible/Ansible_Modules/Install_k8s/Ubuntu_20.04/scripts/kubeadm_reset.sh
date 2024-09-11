kubeadm reset 
rm -rf /etc/cni/net.d
ipvsadm --clear
rm -rf $HOME/.kube/config
rm -rf /run/flannel/subnet.env
