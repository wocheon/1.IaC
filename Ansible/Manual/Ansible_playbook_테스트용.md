# Ansible Playbook 예제

### Ansible Setting
* ssh-keygen 후 ssh-copy-id 진행 <br><br>
* SSH 설정 확인
```bash
 cat /etc/ssh/sshd_config | egrep -e '(PubkeyAuthentication|PermitRootLogin|PasswordAuthentication)' | grep -v '#'
```
>PubkeyAuthentication yes
>PermitRootLogin yes	
>PasswordAuthentication yes 
</br>

* 설정 변경
 
```bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes'/g /etc/ssh/sshd_config 
sed -i 's/PermitRootLogin no/PermitRootLogin yes'/g /etc/ssh/sshd_config 
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes'/g /etc/ssh/sshd_config
systemctl restart sshd
```
</br>

***vm template 용**
```bash
sudo -i << EOF
echo -e 'welcome1\nwelcome1' | /sbin/chpasswd
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config ; setenforce 0; systemctl disable firewalld --now;
yum -y install httpd sshpass expect; systemctl enable  httpd --now 
echo "test web : $(hostname -i)" > /var/www/html/index.html
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes'/g /etc/ssh/sshd_config 
sed -i 's/PermitRootLogin no/PermitRootLogin yes'/g /etc/ssh/sshd_config 
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes'/g /etc/ssh/sshd_config 
systemctl restart sshd
HOSTIP=$(hostname -i)
sshpass -p 'welcome1' ssh -T -o StrictHostKeyChecking=no root@192.168.1.100 "echo $HOSTIP >> /etc/ansible/hosts"
mkdir /root/.ssh 
sshpass -p 'welcome1' ssh -T -o StrictHostKeyChecking=no root@192.168.1.100 "cat /root/.ssh/id_rsa.pub" > /root/.ssh/authorized_keys
EOF
```
</br>

***

</br>

### Ansible Playbook

* 기본 커맨드
 ```bash
ansible all -m ping
ansible all -m shell -a 'ls -lsa'
```

* Ansible_playbooks yml 파일

**1. ping test**

>ping_test.yml

```bash
---
-  name: ping test
   hosts: all
   gather_facts: false
   tasks:
   - name: ping
     ping:
```	 
</br>

**2. shell script copy하여 실행 후 결과 출력**

>shelltest.sh
```bash
hostname > /root/res.txt
hostname -i >> /root/res.txt
df -Ph | grep /dev/sd >> /root/res.txt
```

>shelltest.yml
```bash
---
-  name: shell_test
   hosts: all
   remote_user: root
   gather_facts: false
   tasks:
   - name: cp script
     copy:
       src: "shelltest.sh"
       dest: "shelltest.sh"
   - name: sh script
     shell : |
       sh shelltest.sh
   - name: chck_res
     command: cat res.txt
     register: output
   - debug: var=output.stdout_lines
```
</br>

**3. 신규유저 생성 후, wheel group 추가 및 패스워드 변경**

>passwd_change.sh

```bash
#!/bin/bash
user_name=$1
user_passwd=$2

useradd $user_name
echo $user_name:$user_passwd | /sbin/chpasswd
passwd --expire $user_name
usermod -G wheel $user_name
```

>passwd_change.yml

```yaml
---
-  name: passwd_change
   hosts: all
   remote_user: root
   gather_facts: false
   tasks:
   - name: cp script
     copy:
       src: "passwd_change.sh"
       dest: "passwd_change.sh"
   - name: sh script
     shell : |
       sh passwd_change.sh ciw0707 test1234
     register: output
   - debug: var=output.stdout_lines
```
