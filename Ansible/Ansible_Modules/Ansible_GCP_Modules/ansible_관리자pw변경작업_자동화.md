# Ansible을 통한 관리자 PW 변경작업 자동화 

## 개요 
- 현재 정기적으로 전 서버를 대상으로 관리자 계정 pw를 정기적으로 변경하는 작업 존재

- 작업 대상 서버가 다수이므로 ansible,expect등의 자동화 툴을 사용하여 작업

- 패스워드 변경 작업 시 root권한이 필요함

- root 접근은 가능하나 서버간 root로 ssh 접속은 불가능
    - sshd_config > `PermitrootLogin no`
    
- sudo 권한이 있는경우 sudo로 처리하면 되나 계정 정책상 sudo가 불가능한 상황임
    - become 옵션 사용불가
    
- GCP OS 로그인 옵션으로 인해 ansible에서 root계정 사용이 불가능한 상황으로 가정

    - OS 로그인 옵션으로 인해 root계정의 authorized_key파일 사용 불가능

- 자동으로 root 권한을 획득후에 작업을 진행하도록 expect 스크립트를 작성하여 사용
    - 멱등성 보장이 어렵다는 단점이 존재
    - 작업시 log 파일을 생성하여 작업 내역 및 결과를 기록

    
### 필요 패키지 목록
- Ansible
- Expect

## 작업순서 

1. ansible 설치 후 ssh 접속 활성화

2. 작업 대상 서버에 expect 설치

3. expect를 이용한 root권한 획득 스크립트 작성 (자동로그인)

4. 패스워드 변경용 스크립트 작성

5. 패스워드 변경 결과 확인용 스크립트 작성

6. ansible-playbook 작성 
    - 관리 편의성을 위해 외부 변수 파일 작성
    - 이전 단계에서 작성한 스크립트를 대상 서버에 복사 
    - expect 를 통해 패스워드 변경 스크립트를 실행
    - 패스워드 변경 작업 결과 확인
    - 복사된 스크립트 전체 삭제 진행

7. 실행결과 확인

## 예제 환경 구성


### Management Sever
- 실제 Ansible 커맨드를 사용하는 서버
- 작업 노드를 Inventory로 구성 
- Management 서버도 작업 대상에 포함

- Management Sever (master)

|서버목록|hostname|IP|
|:-:|:-:|:-:|
|Management Sever|master-01|192.168.3.100|



### Worker Sever 
- ansible playbook을 통한 작업이 실행되는 서버
- 여러 대의 서버를 동시에 작업하기위해 5대이상으로 구성
- Management Node에서 worker node로 ssh 접속 가능해야함

|서버목록|hostname|IP|
|:-:|:-:|:-:|
|Worker Sever_1|worker-01|192.168.3.101|
|Worker Sever_2|worker-02|192.168.3.102|
|Worker Sever_3|worker-03|192.168.3.103|
|Worker Sever_4|worker-04|192.168.3.104|
|Worker Sever_5|worker-05|192.168.3.105|


### 계정 정보 
- 일반 사용자 계정
    - 계정명 : wocheon07
    - 해당계정으로 ssh 접근 설정    

- 시스템 관리자 계정 (비밀번호 변경 대상)
    - 계정명 : sysadm
    - 패스워드 변경규칙 
        - #sysadm_AbC@ + IP 마지막자리
        - 업데이트시 뒤 ABC 문자만 랜덤하게 변경하여 적용

### 디렉토리 구성
```
gcp-ansible
|_ 01.copy_scirpt_files.yml
|_ 02.expect_run_scirpt.yml
|_ 03.check_result.yml
|_ 04.delete_scirpts.yml
|_ var_list.yml
|_ scripts
    |_ chpasswd.sh
    |_ expec_su.sh
    |_ sysadm_login_test.sh
```

## 1. ansible 설치 후 ssh 접속 활성화

```bash
#CentOS
yum udate -y 
yum install -y ansible

#Ubuntu
apt upgrade -y && apt update -y 
apt-get install - y ansible
```

### 설치 확인
```bash
$ ansible --version
ansible 2.9.27
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/root/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.5 (default, Jun 20 2023, 11:36:40) [GCC 4.8.5 20150623 (Red Hat 4.8.5-44)]
```


## SSH 설정 
### SSH key pair 생성
```bash
$ ssh-keygen
Generating public/private rsa key pair.

Enter file in which to save the key (/root/.ssh/id_rsa): Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:b59QDHsy2tnCTgF9aV6xa9kMe3gnK3fgNPkeM631KQQ root@ansible-test
The key's randomart image is:
+---[RSA 2048]----+
|              .  |
|         .   . o |
|        . o + +  |
|         . E . X |
|        S = * % *|
|         = O = Oo|
|        . X + ++=|
|         + + = =*|
|          . o o.o|
+----[SHA256]-----+
```

### 공개 키를 authorized_keys 파일에 입력
- host 파일에 ip로 입력하면 자기 자신에도 ssh로 접속하므로 manage 노드에도 작업필요
    - localhost로 입력하면 ssh로 접속 x 

```bash
cat .ssh/id_rsa.pub > .ssh/authorized_keys
# worker 노드에 authorized_keys파일 생성후 공개키 값을 입력
```

## sysadm 계정 생성
- 모든 서버에 syadm계정 생성 후 패스워드 만료일자 90일로 설정

```bash
[root@master-01 ~]# useradd sysadm; chage -M90 sysadm
[root@master-01 ~]# chage -l sysadm
Last password change                                    : Jan 26, 2024
Password expires                                        : Apr 25, 2024
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 90
Number of days of warning before password expires       : 7
```

### ssh 공개키 복사 
- master 서버의 root 공개키를 각 서버의 개인계정에 등록
    - master 서버도 작업 필요

- ssh-copy-id가 불가하므로 수동으로 입력 

```bash
[root@master-01 wocheon07]#  cat /root/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsqnZAQKBtydbn040mWetqauZ6Kx+a7r5B4AH4gv2iPmRpSJdBsphKioxaeQ0F9+h5DMY5xfEQIW2PXc7UM9+we2OHf0pirgA1QTXPOoXBmd31Z1dMWMlIBIpXjoyLZ79XHRk9r0U7hoO9/zAUrG49csq+bfRPYZG8GtQcXnRa7mVeapTxIHeHmoiEXTOMx4qG/8iR/BfWjLn55RXXwHDHgq4pm+3NBCiZzV+EgMKLppP2tM4x6Dq8WZT5yxbTGjSypfYULiLB5dPLx2t3KuiCnQBRephhb9pzcrxQAeh7AHI5EmRs8o5W6bCK6iwTPmnRHqeIvWc9Xo2gJLqYXSZd root@master-01


[root@master-01 wocheon07]# mkdir /home/wocheon07/.ssh; cd /home/sysadm/.ssh

[root@master-01 wocheon07]# echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsqnZAQKBtydbn040mWetqauZ6Kx+a7r5B4AH4gv2iPmRpSJdBsphKioxaeQ0F9+h5DMY5xfEQIW2PXc7UM9+we2OHf0pirgA1QTXPOoXBmd31Z1dMWMlIBIpXjoyLZ79XHRk9r0U7hoO9/zAUrG49csq+bfRPYZG8GtQcXnRa7mVeapTxIHeHmoiEXTOMx4qG/8iR/BfWjLn55RXXwHDHgq4pm+3NBCiZzV+EgMKLppP2tM4x6Dq8WZT5yxbTGjSypfYULiLB5dPLx2t3KuiCnQBRephhb9pzcrxQAeh7AHI5EmRs8o5W6bCK6iwTPmnRHqeIvWc9Xo2gJLqYXSZd root@gcp-master-01" >  /home/wocheon07/.ssh/authorized_keys


[root@master-01 .ssh]# chmod 600 authorized_keys
[root@master-01 .ssh]# chown wocheon07.wocheon07 authorized_keys

[root@master-01 .ssh]# ll
total 4
-rw------- 1 wocheon07 wocheon07 403 Jan 26 07:42 authorized_keys
```

- 나머지 서버에도 동일하게 작업 진행

### ssh 접속 확인

- worker노드에 ssh 접속 가능한지 확인

- ssh 키를 복사했으므로 패스워드 입력 없이 sysadm 접근 확인

```
[root@master-01 ~]# ssh wocheon07@192.168.3.100
Last login: Mon Jan 29 00:39:25 2024 from master-01.asia-northeast1-a.c.test-project.internal
[wocheon07@master-01 ~]$ logout
Connection to 192.168.3.100 closed.
[root@master-01 ~]# ssh wocheon07@192.168.3.101
Last login: Mon Jan 29 00:41:28 2024 from master-01.asia-northeast1-a.c.test-project.internal
[wocheon07@worker-01 ~]$ logout
Connection to 192.168.3.101 closed.
[root@master-01 ~]# ssh wocheon07@192.168.3.102
Last login: Thu Jan 25 08:06:52 2024 from 165.243.5.20
[wocheon07@worker-02 ~]$ logout
Connection to 192.168.3.102 closed.
[root@master-01 ~]# ssh wocheon07@192.168.3.103
Last login: Thu Jan 25 08:06:52 2024 from 165.243.5.20
[wocheon07@worker-03 ~]$ logout
Connection to 192.168.3.103 closed.
[root@master-01 ~]# ssh wocheon07@192.168.3.104
Last login: Thu Jan 25 08:06:52 2024 from 165.243.5.20
[wocheon07@worker-04 ~]$ logout
Connection to 192.168.3.104 closed.
[root@master-01 ~]# ssh wocheon07@192.168.3.105
Last login: Thu Jan 25 08:06:52 2024 from 165.243.5.20
[wocheon07@worker-05 ~]$ logout
Connection to 192.168.3.105 closed.
```

### ansible remote user 설정 
- ansble을 통해 명령을 수행할 계정을 wocheon07으로 설정

>vi /etc/ansible/ansible.cfg
```bash
# 해당 부분 주석 해제 후 root > sysadm으로 변경
# default user to use for playbooks if user is not specified
# (/usr/bin/ansible will use current user as default)
remote_user = wocheon07
```


### Ansible inventory file 작성

> vi /etc/ansible/hosts
```
[master]
192.168.3.100

[worker]
192.168.3.100
192.168.3.101
192.168.3.102
192.168.3.103
192.168.3.104
192.168.3.105
```

### Ansible 연결 확인 
- ansible 기본모듈인 ping으로 연결확인

```
$ ansible all -m ping
192.168.3.103 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.3.101 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.3.102 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.3.104 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.3.100 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.3.105 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```



## 2. expect 설치

- 작업 대상 서버에 자동로그인 스크립트를 실행하기 위한 expect 패키지 설치 필요 

```bash
#CentOS
yum install -y expect 

#Ubuntu
apt-get install -y expect 
```

## 3. expect를 이용한 root권한 획득 스크립트 작성 
- root 자동로그인 후 스크립트를 실행하는 스크립트를 작성

### expect_su.sh

- expect를 통해 root로 로그인하여 root권한이 필요한 다른 스크립트를 실행하는 용도

```bash
#!/bin/bash

script_path=$1

ip=$(hostname -i | gawk '{print $1}')
host_nm=$(hostname | gawk -F'_' '{print $1}')

pass="welcome1"

expect << EOF
spawn su
expect "Password:"
sleep 1
send "$pass\n"
send "sh $script_path $2; exit;\n"
expect eof
EOF

exit
```

## 4. 패스워드 변경용 스크립트 작성
> chpasswd.sh
```bash
#!/bin/bash

ip=$(hostname -i | gawk '{print $1}' | gawk -F"." '{print $4}')
srv_nm=$(hostname | gawk -F'_' '{print $1}')
today=$(date '+%Y-%m-%d')

user=sysadm

new_pw=$1${ip}

exec >> chpasswd.log

echo "${user}:${new_pw}" | /usr/sbin/chpasswd

chage -d ${today} ${user}

if [ $? -eq 0 ]; then
    echo "======================================"
    echo "Server : ${srv_nm} User : ${user}"
    echo "Password Change Success"
    chage -l ${user} | head -n 2
    echo "======================================"

else
    echo "======================================"
    echo "Server : ${srv_nm} User : ${user}"
    echo "!ERROR : Fail to Change Password"
    echo "======================================"

fi

exec >> /dev/tty

chown wocheon07.wocheon07 chpasswd.log
```


## 5. 패스워드 변경 결과 확인용 스크립트 작성
- expect를 통해 sysadm 계정 패스워드 변경 확인

>vi sysadm_login_test.sh
```bash
#!/bin/bash

cmd="whoami"
ip=$(hostname -i | gawk '{print $1}' | gawk -F"." '{print $4}')
pass=$1${ip}

expect << EOF
spawn su sysadm
expect "Password:"
sleep 1
send "$pass\n"
send "$cmd; exit;\n"
expect eof
EOF
```

## 6. ansible-playbook 작성 

- playbook 작성은 3개로 구분하여 작성
    - 각 단계별로 실행하면서, 오류 발생시 트러블슈팅 진행

- 추후 관리 용이성을 위해 외부 변수 파일을 생성하여 관리 

### 6-1. 외부 변수 파일 생성 

> vi var_list.yml
```yml
### 기본 설정 변수 ###
copy_path: /home/sysadm/
expect_script: expect_su.sh
file_nm_1: chpasswd.sh
file_nm_2: sysadm_login_test.sh
log_file: chpasswd.log

#### 패스워드 변경규칙 ###
## #이 주석처리되지 않도록 따옴표로 묶어서 선언
password_rule: '#sysadm_AbC@'
```

### 6-2. 작업대상에 스크립트 복사하는 playbook 작성

> 01.copy_scirpt_files.yml

```yml
- name: task1 - copy script files
  hosts: worker
  gather_facts: no
  become: false
  vars_files: var_list.yml

  tasks:
    - name: copy expect scirpt
      copy:
        src: "{{ playbook_dir }}/scripts/{{ expect_script }}"
        dest: "{{ copy_path }}{{ expect_script }}"
        mode: 0755
      tags: expect

    - name: copy scirpt file_1 - chpasswd
      copy:
        src: "{{ playbook_dir }}/scripts/{{ file_nm_1 }}"
        dest: "{{ copy_path }}{{ file_nm_1 }}"
        mode: 0755
      tags: file_1

    - name: copy scirpt file_2 - sysadm_login_test.sh
      copy:
        src: "{{ playbook_dir }}/scripts/{{ file_nm_2 }}"
        dest: "{{ copy_path }}{{ file_nm_2 }}"
        mode: 0755
      tags: file_2
   
```

### 6-3. expect를 사용한 패스워드 변경 스크립트 실행

> 02.expect_run_scirpt.yml
```yml
- name: task2 - run script by expect script
  hosts: worker
  gather_facts: no
  become: false
  vars_files: var_list.yml

  tasks:
  - name: run script by expect_script
    shell: |
      bash {{ expect_script }} '{{ copy_path }}{{ file_nm_1 }}' "'{{ password_rule }}'"
    register: res

  - name: debug
    debug: var=res.stdout_lines
```

### 6-4. 패스워드 변경 로그 확인 및 테스트 진행

> 03.check_result.yml

```yml
- name: task3 - check password change result
  hosts: worker
  gather_facts: no
  become: false
  vars_files: var_list.yml

  tasks:
  - name: cat password_change_log
    shell: |
      cat chpasswd.log
    register: res_1

  - name: debug_1
    debug: var=res_1.stdout_lines

  - name: use changed_password login test
    shell: |
      bash sysadm_login_test.sh '{{ password_rule }}'
    register: res_2

  - name: debug_2
    debug: var=res_2.stdout_lines
```


### 6-5. 복사한 스크립트 삭제 처리

> 04.delete_scirpts.yml
```yml
- name: task4 - delete copied script files
  hosts: worker
  gather_facts: no
  become: false
  vars_files: var_list.yml

  tasks:
  - name: rm expect scirpt
    file:
      path: "{{ expect_script }}"
      state: absent

  - name: rm script file_1 - chpasswd.sh
    file:
      path: "{{ file_nm_1 }}"
      state: absent

  - name: rm script file_2 - chpasswd.sh
    file:
      path: "{{ file_nm_2 }}"
      state: absent

  - name: rm log file - chpasswd.log
    file:
      path: "{{ log_file }}"
      state: absent
```

## 7. 실행결과 확인
- ansible-playbook - 01.copy_scirpt_files.yml
```
[root@master-01 gcp-ansible]# ansible-playbook 01.copy_scirpt_files.yml

PLAY [task1 - copy script files] *****************************************************************************************************************************************************************************

TASK [copy expect scirpt] ************************************************************************************************************************************************************************************
changed: [192.168.3.101]
changed: [192.168.3.104]
changed: [192.168.3.103]
changed: [192.168.3.102]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [copy scirpt file_1 - chpasswd] *************************************************************************************************************************************************************************
changed: [192.168.3.102]
changed: [192.168.3.104]
changed: [192.168.3.103]
changed: [192.168.3.101]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [copy scirpt file_2 - sysadm_login_test.sh] *************************************************************************************************************************************************************
changed: [192.168.3.102]
changed: [192.168.3.103]
changed: [192.168.3.101]
changed: [192.168.3.104]
changed: [192.168.3.100]
changed: [192.168.3.105]

PLAY RECAP ***************************************************************************************************************************************************************************************************
192.168.3.100              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.101              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.102              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.103              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.104              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.105              : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0


```

- ansible-playbook - 02.expect_run_scirpt.yml

```
[root@master-01 gcp-ansible]# ansible-playbook 02.expect_run_scirpt.yml

PLAY [task2 - run script by expect script] *******************************************************************************************************************************************************************

TASK [run script by expect_script] ***************************************************************************************************************************************************************************
changed: [192.168.3.104]
changed: [192.168.3.101]
changed: [192.168.3.103]
changed: [192.168.3.102]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [debug] *************************************************************************************************************************************************************************************************
ok: [192.168.3.100] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@master-01:/home/wocheon07\u0007\u001b[?1034h[root@master-01 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}
ok: [192.168.3.103] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@worker-03:/home/wocheon07\u0007\u001b[?1034h[root@worker-03 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}
ok: [192.168.3.105] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@worker-05:/home/wocheon07\u0007\u001b[?1034h[root@worker-05 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}
ok: [192.168.3.101] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@worker-01:/home/wocheon07\u0007\u001b[?1034h[root@worker-01 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}
ok: [192.168.3.102] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@worker-02:/home/wocheon07\u0007\u001b[?1034h[root@worker-02 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}
ok: [192.168.3.104] => {
    "res.stdout_lines": [
        "spawn su",
        "Password: ",
        "\u001b]0;wocheon07@worker-04:/home/wocheon07\u0007\u001b[?1034h[root@worker-04 wocheon07]# sh /home/wocheon07/chpasswd.sh '#sysadm_AbC@'; exit; ",
        "\u001b[A\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[C\u001b[K;",
        "exit"
    ]
}

PLAY RECAP ***************************************************************************************************************************************************************************************************
192.168.3.100              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.101              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.102              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.103              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.104              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.105              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

- ansible-playbook - 03.check_result.yml

```
[root@master-01 gcp-ansible]# ansible-playbook 03.check_result.yml

PLAY [task3 - check password change result] ******************************************************************************************************************************************************************

TASK [cat password_change_log] *******************************************************************************************************************************************************************************
changed: [192.168.3.103]
changed: [192.168.3.102]
changed: [192.168.3.101]
changed: [192.168.3.104]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [debug_1] ***********************************************************************************************************************************************************************************************
ok: [192.168.3.100] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : master-01 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}
ok: [192.168.3.102] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : worker-02 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}
ok: [192.168.3.101] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : worker-01 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}
ok: [192.168.3.103] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : worker-03 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}
ok: [192.168.3.104] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : worker-04 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}
ok: [192.168.3.105] => {
    "res_1.stdout_lines": [
        "======================================",
        "Server : worker-05 User : sysadm",
        "Password Change Success",
        "Last password change\t\t\t\t\t: Jan 29, 2024",
        "Password expires\t\t\t\t\t: Apr 28, 2024",
        "======================================"
    ]
}

TASK [use changed_password login test] ***********************************************************************************************************************************************************************
changed: [192.168.3.101]
changed: [192.168.3.103]
changed: [192.168.3.104]
changed: [192.168.3.100]
changed: [192.168.3.102]
changed: [192.168.3.105]

TASK [debug_2] ***********************************************************************************************************************************************************************************************
ok: [192.168.3.100] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@master-01:/home/wocheon07\u0007\u001b[?1034h[sysadm@master-01 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}
ok: [192.168.3.102] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@worker-02:/home/wocheon07\u0007\u001b[?1034h[sysadm@worker-02 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}
ok: [192.168.3.101] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@worker-01:/home/wocheon07\u0007\u001b[?1034h[sysadm@worker-01 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}
ok: [192.168.3.103] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@worker-03:/home/wocheon07\u0007\u001b[?1034h[sysadm@worker-03 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}
ok: [192.168.3.104] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@worker-04:/home/wocheon07\u0007\u001b[?1034h[sysadm@worker-04 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}
ok: [192.168.3.105] => {
    "res_2.stdout_lines": [
        "spawn su sysadm",
        "Password: ",
        "\u001b]0;sysadm@worker-05:/home/wocheon07\u0007\u001b[?1034h[sysadm@worker-05 wocheon07]$ whoami; exit;",
        "sysadm",
        "exit"
    ]
}

PLAY RECAP ***************************************************************************************************************************************************************************************************
192.168.3.100              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.101              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.102              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.103              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.104              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.105              : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

- ansible-playbook 04.delete_scirpts.yml

```bash

[root@master-01 gcp-ansible]# ansible-playbook 04.delete_scirpts.yml

PLAY [task4 - delete copied script files] ********************************************************************************************************************************************************************

TASK [rm expect scirpt] **************************************************************************************************************************************************************************************
changed: [192.168.3.102]
changed: [192.168.3.103]
changed: [192.168.3.104]
changed: [192.168.3.101]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [rm script file_1 - chpasswd.sh] ************************************************************************************************************************************************************************
changed: [192.168.3.103]
changed: [192.168.3.102]
changed: [192.168.3.101]
changed: [192.168.3.104]
changed: [192.168.3.100]
changed: [192.168.3.105]

TASK [rm script file_2 - chpasswd.sh] ************************************************************************************************************************************************************************
changed: [192.168.3.103]
changed: [192.168.3.100]
changed: [192.168.3.102]
changed: [192.168.3.104]
changed: [192.168.3.101]
changed: [192.168.3.105]

TASK [rm log file - chpasswd.log] ****************************************************************************************************************************************************************************
changed: [192.168.3.103]
changed: [192.168.3.101]
changed: [192.168.3.100]
changed: [192.168.3.104]
changed: [192.168.3.102]
changed: [192.168.3.105]

PLAY RECAP ***************************************************************************************************************************************************************************************************
192.168.3.100              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.101              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.102              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.103              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.104              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.3.105              : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 에러 처리

### ssh 접속 불가 
- /etc/ssh/sshd_config 파일 설정 확인
    - PubkeyAuthentication yes
    - AuthorizedKeysFile      .ssh/authorized_keys


- .ssh 및 authorized_keys 권한, 소유자 확인
```
[root@master-01 gcp-ansible]# ssh 192.168.3.101
Permission denied (publickey,gssapi-keyex,gssapi-with-mic).

[root@worker-01 .ssh]# ll
total 16
-rw-rw-rw-. 1 root root  403 Jan 25 06:34 authorized_keys
```


- 변경 후 sshd 재시작


### ansible 기본 디렉토리 권한문제
- playbook 실행시 다음 에러가 발생하는 경우 홈디렉토리의 .ansible디렉토리 권한을 확인해볼 것


- 에러발생
```bash
PLAY [task1 - copy script files] *****************************************************************************************************************************************************************************

TASK [copy expect scirpt] ************************************************************************************************************************************************************************************
fatal: [192.168.3.102]: UNREACHABLE! => {"changed": false, "msg": "Failed to create temporary directory.In some cases, you may have been able to authenticate and did not have permissions on the target directory. Consider changing the remote tmp path in ansible.cfg to a path rooted in \"/tmp\", for more error information use -vvv. Failed command was: ( umask 77 && mkdir -p \"` echo /home/wocheon07/.ansible/tmp `\"&& mkdir \"` echo /home/wocheon07/.ansible/tmp/ansible-tmp-1706489293.03-3985-83962787573887 `\" && echo ansible-tmp-1706489293.03-3985-83962787573887=\"` echo /home/wocheon07/.ansible/tmp/ansible-tmp-1706489293.03-3985-83962787573887 `\" ), exited with result 1", "unreachable": true}
```


- ansible 기본 디렉토리 권한 확인
```bash
#권한 확인
[wocheon07@worker-01 ~]$ ls -la
total 16
drwx------. 4 wocheon07 wocheon07 111 Jan 25 07:59 .
drwxr-xr-x. 6 root      root       70 Jan 29 00:40 ..
drwx------. 3 root      root       17 Jan 25 06:31 .ansible   #소유자/그룹이 root
-rw-------. 1 wocheon07 wocheon07   9 Jan 25 07:59 .bash_history
-rw-r--r--. 1 wocheon07 wocheon07  18 Nov 24  2021 .bash_logout
-rw-r--r--. 1 wocheon07 wocheon07 193 Nov 24  2021 .bash_profile
-rw-r--r--. 1 wocheon07 wocheon07 231 Nov 24  2021 .bashrc
drwx------. 2 wocheon07 wocheon07  29 Jan 29 00:17 .ssh

# chown으로 소유자 변경
[root@worker-01 ~]$ chown -R wocheon07.wocheon07 /home/wocheon07


# 정상 실행 확인
PLAY [task1 - copy script files] *****************************************************************************************************************************************************************************

TASK [copy expect scirpt] ************************************************************************************************************************************************************************************
changed: [192.168.3.102]
```




## 추가 - root로 ssh 접속이 가능한 경우
- 만약 root로 ssh접속이 가능한 환경이라면 다음과 같은 방법으로도 적용 가능

>passwd_change.yml
```yml
- name: Step1 - password change by root
  hosts: worker
  gather_facts: no
  become: true
  vars_files: var_list.yml

  tasks:

  - name: usercheck_1
    shell: |
      whoami
    register: res

  - name: Check user_name
    debug: var=res.stdout_lines

  - name: ip check
    shell: |
      echo "{{ password_rule }}$(hostname -i | gawk '{print $1}' | gawk -F"." '{print $4}')"
    register: PASSWORD

#  - name: print passwd
#    debug: var=PASSWORD.stdout_lines

  - name: change_passwd
    user:
      name: "sysadm"
      password: "{{ PASSWORD.stdout | password_hash('sha512') }}"

- name: Step2 - changed passwd check
  hosts: worker
  gather_facts: no
  become: false
  vars_files: var_list.yml
  remote_user: wocheon07

  tasks:

  - name: usercheck_2
    shell: |
      whoami
    register: res

  - name: Check user_name
    debug: var=res.stdout_lines

  - name: copy scirpt file - sysadm_login_test.sh
    copy:
      src: "{{ playbook_dir }}/scripts/{{ file_nm_2 }}"
      dest: "{{ copy_path }}{{ file_nm_2 }}"
      mode: 0755
    tags: file_2

  - name: use changed_password login test
    shell: |
      bash sysadm_login_test.sh '{{ password_rule }}'
    register: res_2

  - name: debug_2
    debug: var=res_2.stdout_lines
```