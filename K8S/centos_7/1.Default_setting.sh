#!/bin/bash
sudo -i << EOF
echo "root:welcome1" | /sbin/chpasswd
echo "wocheon07:welcome1" | /sbin/chpasswd
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config ; setenforce 0
systemctl disable firewalld --now
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd
yum install -y git curl wget ansible bash-completion
echo "$(hostname -i) $(hostname)" >> /etc/hosts
EOF
