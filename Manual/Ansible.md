# Ansible

## 개요

### Infrastructure as a Code(IaC)

- Infrastructure as a Code
    - 코드를 통해 인프라를 관리하고 프로비저닝하는 역할

### Ansible

- python으로 개발된 오픈소스 Infrastructure as a Code 툴
- 시스템 구성, 애플리케이션 배포 등 여러 IT 프로세스를 자동화할수 있음
- Management 노드에만 Ansible을 설치하면 다른 working노드들에 Agent등을 설치할 필요없이 SSH 설정만으로 작동 가능 
    - 주로 SSH 로 동작하므로 편의를 위해 공개키를 생성 후 를 통해 접속하도록 설정
   
### Ansible 특징    
1. 멱등성 지원 
    - 멱등성
        - 여러번 실행해도 같은 결과 값이 나오는 성질
    - Ansible에서의 멱등성
        - 결과의 상태값이 다르더라도 결국에 결과는 동일하게 나오게 하는 성질

2. Modular
    - 많은 모듈 지원 
    - Shell에 의존하지 않고 Ansible에서 지원하는 Module로 구성관리에 용이함

3. YAML 형식 지원
    - 기존의 Shell Scripts보다 간편하게 구성 가능

4. 대형 워크로드에 용이
    - 많은 서버에 구성이 필요한 경우 Shell Scripts보다 신속하게 처리 가능

5. Agent 필요 없음
    - 따로 Agent를 설치하지 않고 SSH로 통신하는 방식을 사용
    - Kerberos, LDAP 등의 다른 인증 방식도 지원


## Ansible 설치 및 실행 

### 테스트 환경 구성
- OS : CentOS7

- Management Node(master)
    - 192.168.1.89

- Worker Node
     - 192.168.1.90


- GCP 환경에서는 패키지 update 후 바로 설치가 가능함.

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
```bash
ssh root@192.168.1.90
```


## Ansible Inventory 파일 수정 

- 기본 inventory 파일
    - /etc/ansible/hosts

>/etc/ansible/hosts
```bash
# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups

#...

# master를 자기 자신으로 지정
[master]
#localhost
192.168.1.89

# worker노드 ip를 지정
[worker]
192.168.1.90
```

### Ansible-inventory 확인
- list 옵션

```bash
$ ansible-inventory --list
{
    "_meta": {
        "hostvars": {}
    },
    "all": {
        "children": [
            "master",
            "ungrouped",
            "worker"
        ]
    },
    "master": {
        "hosts": [
            "192.168.1.89"
        ]
    },
    "worker": {
        "hosts": [
            "192.168.1.90"
        ]
    }
}
```
- graph 옵션
```bash
$ ansible-inventory --graph
@all:
  |--@master:
  |  |--192.168.1.89
  |--@ungrouped:
  |--@worker:
  |  |--192.168.1.90
```

## Ansible - 명령문으로 실행 
- 몇가지 간단한 모듈은 playbook 작성 없이 명령어로 실행 가능함

### ping 
```bash
$ ansible all -m ping

192.168.1.90 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.1.89 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}

# 오류 발생시 SSH 설정이 잘못된것이므로 확인
```

### Shell
```bash
$ ansible all -m shell -a "pwd; whoami; ls -l"

192.168.1.89 | CHANGED | rc=0 >>
/root
root
total 8
drwxr-xr-x. 8 root root 100 Aug 30 04:22 ansible
-rw-r--r--. 1 root root 694 Aug 30 05:45 var_test.yml
-rw-r--r--. 1 root root  13 Aug 30 05:05 vault_passfile
192.168.1.90 | CHANGED | rc=0 >>
/root
root
total 0
```

## Ansible 작업 결과 표기
|작업결과|설명|
|:-:|:-|
|OK|호스트 값의 상태와 매개변수의 차이가 없으므로 아무 작업 하지않음|
|CHANGED|호스트 값의 상태와 매개변수의 차이가 존재하여 변경을 적용|
|failed | 오류로 인해 작업 실패 |



## Ansible-playbook
- Ansible-playbook
    - Ansible의 configuration, deployment, orchestration 언어
    - 여러번 작업해야하는 경우 ansible-playbook 파일을 통해 작업이 가능
    - yaml 파일로 작성
    - 위에서 아래로 순서대로 실행
    - 하나의 play 안에 task들로 구성되어있음
    - 들여쓰기에 민감하므로 주의하여 작성

### ansible-playbook  옵션 

#### * ansible-playbook 쉘 명령어 옵션
|옵션|특징|
|:-:|:-|
|--start-at-task |특정 task부터 실행시 사용|
|--step|각 task 별로 실행 여부를 확인 하면서 진행|
|--timeout|timeout 설정 시 사용|
|--check|실제 실행하지않고 모듈 테스트만 진행|
|--diff|- copy등의 모듈로 파일 전송시 원격지의 파일과 src파일을 비교<br> - 주로 check와 같이 사용하여 전송전에 확인할때 사용|
|--syntax-check|실제 실행하지않고 문법만 체크|
|--list-hosts |플레이북이 실행될 `호스트`를 나열|
|--list-tasks |플레이북에서 실행될 `task`를 나열|
|--user|- REMOTE_USER를 지정 <br> - 대체로 playbook내에서 지정하여 사용|
|--vault-password-file|ansible-vault 사용시 패스워드 파일을 지정|
|--skip-tags|- 지정한 태그의 task는 skip하면서 실행 <br> - register와 유사하게 task별로 태그를 지정하여 사용|

#### * playbook 내부 옵션
|옵션|특징|
|:-:|:-|
|hosts|- Remote host 이름 <br>- inventory에 명시된 host명 사용<br>- all 로 사용하면 inventory파일에 존재하는 모든 Host에서 실행|
|remote_user| 원격 접속시 사용할 계정을 지정|
| become|- 명령을 실행하는 사용자 계정의 권한을 승격(sudo)<br>- `true` / `false`|
|gather_facts|- 원격 대상 시스템의 호스트 네임, CPU, Memory 정보 등을 수집하는 setup 모듈 <br> - `yes`/`no`|
|tasks| Remote host에서 수행할 작업들 |
|vars|- play내에서 사용할 변수 선언 시 사용<br>- key:value 형태로 선언함|

### playbook 예시

```yml
#play_1
- name: Tomcat Setup
  hosts: master
  remote_user: ciw0707
  become: yes
  gather_facts: no
  vars:
    pkg_nm: openjdk-8-jdk
   #task 시작
  tasks:
   #task1   
  - name: os chck
    shell: |
      cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/\"//g'
    register: os_chck
   #task2
  - name: set fact
    set_fact: os_chck={{ os_chck.stdout }}
   #task3
  - name: Install JDK - Ubuntu
    apt:
      name: {{ pkg_nm }}
      state: present
    when: os_chck == "ubuntu"
    # 모든 task 종료
# play_1 종료

#play_2     
- name: Tomcat status check
  hosts: master
  remote_user: root
  become: yes
  gather_facts: no 
  tasks:    
    #task 1
    - name: status check
      systemd:
        name: tomcat
      register: res
    # task 2
    - debug: var=res.status.Names,res.status.ActiveState,res.status.UnitFileState
    #모든 task 종료
# play_2 종료
```


## Ansible 모듈 

### 주로 사용되는 모듈 
|모듈명|주 사용 용도|
|:-:|:-------------|
|ping | host의 연결상태 확인|
|copy| - 특정 파일을 대상서버에 전송하는 경우 사용<br>- 기본 위치는 Remote User의 홈 디렉토리로 지정됨|
|fetch|- 특정 파일을 대상서버에서 가져오는 경우 사용<br>- 기본 위치는 Remote User의 홈 디렉토리로 지정됨|
|file|- 파일의 권한, 속성생성, 복사, 편집, 제거, 수정등 <br> 파일관리와 관련된 대부분의 작업을 수행할 수 있는 모듈
|lineinfile|- 기존 텍스트로 된 파일의 맨 아래에 라인을 추가하는 모듈 <br> - 특정 문자열을 치환하는 경우에도 사용 가능|
|blockinfile|- 기존 텍스트로 된 파일의 맨 아래에 한 라인이 아닌 여러 라인으로 이루어진 텍스트 블록을 추가하는 모듈|
|register| task 실행 결과를 변수값으로 저장|
|set_fact| play 중간에 변수를 선언하는 경우에 사용|
|debug|- 주로 출력값을 확인하는 경우에 사용<br>- task에 변수값을 할당 (register) 하여 debug로 출력하는 형태<br>- 변수에 출력값을 입력하고 해당 값을 출력|
|shell|- 여러가지 모듈이 많지만 사실 shell로 대부분의 동작은 가능<br>- shell 스크립트 형태로 만들어서 진행가능<br>- 한 task에서 여러 라인을 수행가능<br>- 그러나 멱등성이 보장되지않으므로 사용에 주의할것<br><br>* `멱등성 관련 예시`<br>- copy 모듈을 사용하면 동일한 파일은 복사하지않음<br>- shell로 파일을 복사하면 동일한 파일이어도 복사를 진행<br><br>- reigister로 등록 후 `changed_when: [register].rc != 0`옵션을 주면 명령어가 실패하지 않으면 ok로 표기<br> ($?와 동일 역할)|
|systemd|- 서비스 관련작업을 진행하는 경우 사용<br>- status , enable ,stop, reload, start 등의 작업 가능
|yum/apt| 패키지 다운로드시 사용|
|get_url|- 특정 링크를 통해 파일 다운로드시 사용<br>- wget 과 동일|
|archive|- 압축파일 생성시 사용<br>- tar cvzf 과 동일|
|unarchive|- 압축파일을 해제할때 사용<br>- tar xvzf 역할|
|stat|- 특정 파일의 상태 및 정보를 확인시 사용|


### Ansible 모듈 검색

```bash
# 전체 모듈 리스트 출력
ansible-doc -l

# 특정 모듈 사용법 확인
ansible-doc file

# 특정모듈 사용법을 플레이북 형태로 출력
ansible-doc file -s 
```

## Ansible-playbook task별 Tag 지정
```yaml
 - name: chown&chmod root 400 /etc/security/passwd
    file:
      path: "/etc/security/passwd"
      owner: "root"
      mode: 0400
    register: command_output
    tags: chmod_secpasswd
  - debug:
      var: command_output
    when: ""
    tags: chmod_secpasswd
```    
