#!/bin/bash
sudo -i << EOF
echo "root:welcome1" | /usr/sbin/chpasswd
echo "wocheon07:welcome1" | /usr/sbin/chpasswd
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab ; swapoff -a ;
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd
EOF
apt update -y && apt upgrade -y
apt-get install -y git curl wget ansible bash-completion
