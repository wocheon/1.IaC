[K8S Install by Ansible ]

* Auto Install K8S using by Ansible 


* Necessary Packages
- git
- curl
- wget
- ansible

* Prepare 
1. SSH check ( ssh-keygen > ssh-copy-id or copy public key to .ssh/authorized_keys )

2. /etc/ansible/hosts setting
	- [k8s] : master & worker nodes ip
	- [master] : master node ip
	- [worker] : worker node ip

3. Ansible work check > ansible all -m ping 

