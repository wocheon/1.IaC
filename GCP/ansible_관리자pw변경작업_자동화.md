# Ansible을 통한 관리자 PW 변경작업 자동화 

## 개요 
- 현재 정기적으로 전 서버를 대상으로 관리자 계정 pw를 정기적으로 변경하는 작업 존재

- 작업 대상 서버가 다수이므로 ansible,expect등의 자동화 툴을 사용하여 작업

- 패스워드 변경 작업 시 root권한이 필요함
    
- sudo 권한이 있는경우 sudo로 처리하면 되나 계정 정책상 sudo가 불가능한 상황임
    - become 옵션 사용불가
    
- OS 로그인이 되어있는 상태이므로 ansible에서 root계정 사용이 불가능한 상황
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
|Management Sever|master|192.168.1.90|



### Worker Sever 
- ansible playbook을 통한 작업이 실행되는 서버
- 여러 대의 서버를 동시에 작업하기위해 5대이상으로 구성
- Management Node에서 worker node로 ssh 접속 가능해야함

|서버목록|hostname|IP|
|:-:|:-:|:-:|
|Worker Sever_1|worker_1|192.168.1.91|
|Worker Sever_2|worker_2|192.168.1.92|
|Worker Sever_3|worker_3|192.168.1.93|
|Worker Sever_4|worker_4|192.168.1.94|
|Worker Sever_5|worker_5|192.168.1.95|


### 계정 정보 
- 일반 사용자 계정
    - 계정명 : wocheon07

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

### ssh 접속 확인
- worker노드에 ssh 접속 가능한지 확인

- ssh 키를 복사했으므로 패스워드 입력 없이 ssh 접근 확인

```bash
ssh root@127.0.0.1
ssh root@192.168.1.91
ssh root@192.168.1.92
ssh root@192.168.1.93
ssh root@192.168.1.94
ssh root@192.168.1.95
```

### Ansible inventory file 작성
```
[master]
192.168.1.89

[worker]
192.168.1.89
192.168.1.90
192.168.1.91
192.168.1.92
192.168.1.93
192.168.1.94
```

### Ansible 연결 확인 

```
ansible all -m ping 
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

if [ $host_nm == 'test' ] || [ $host_nm = 'dev' ]; then
    pass="welcome1"
else
     pass="prod$(hostname -i | gawk '{print $1}' | gawk -F'.' '{print $4}')"
fi

expect << EOF
spawn su 
expect "Password:"
sleep 1
send "$pass\n"
send "sh $script_path; exit;\n"
expect eof
EOF

exit
```

## 4. 패스워드 변경용 스크립트 작성
> chpasswd.sh
```bash
#!/bin/bash

ip=$(hostname -i | gawk '{print $1}')
srv_nm=$(hostname | gawk -F'_' '{print $1}')
today=$(date '+%Y-%m-%d')

user=sysadm

new_pw=$2{ip}

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

> expect_su.sh
```bash
#!/bin/bash

cmd="whoami"
ip=$(hostname -i | gawk '{print $1}')

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
copy_path: /home/wocheon07/
expect_script: expect_su.sh
file_nm_1: chpasswd.sh
file_nm_2: sysadm_login_test.sh
log_file: chpasswd.log

### 패스워드 변경규칙 ###
# #이 주석처리되지 않도록 따옴표로 묶어서 선언
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
        dest: "{{ copy_path }}{{ expects_script }}"
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
  - name: run script by expect script
    shell: |
      bash {{ expect_script }} '{{ copy_path }}{{ file_nm_1 }}' "'{{ password_rule }}'"
    
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

