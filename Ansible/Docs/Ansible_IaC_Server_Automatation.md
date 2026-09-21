Ansible을 활용한 IaC 기반 서버 구성 자동화

# 개요

여러 서버를 직접 관리하다 보면 같은 패키지 설치, 설정 파일 배포, 서비스 재시작 작업이 반복된다.

서버 수가 늘어날수록 수동 작업은 누락, 순서 오류, 환경 차이, 작업 이력 부재 같은 문제를 만들기 쉽다.

이때 Ansible이라는 자동화 도구를 사용하면 반복 작업을 코드로 정의하여 여러 서버에 동일한 구성을 한 번에 적용가능하며, 이를 통해 작업 시간을 단축하고 작업 공수를 줄일 수 있다.

# 1\. Ansible 개념과 특징

Ansible은 Python 기반의 오픈소스 Infrastructure as Code(IaC) 도구이다. 서버 구성 관리, 애플리케이션 배포, 파일 배포, 서비스 제어, 반복 운영 작업을 코드로 정의해 여러 대상에 일관되게 적용할 수 있다.

Ansible의 주요 특징은 다음과 같다.

* Idempotency(멱등성): 같은 작업을 반복 실행해도 최종 상태가 같도록 설계한다.  
* 모듈 기반 구조: Shell Script에만 의존하지 않고 목적별 모듈로 작업을 표현한다.  
* YAML 형식: 플레이북을 사람이 읽기 쉬운 선언형 문법으로 작성한다.  
* 대규모 서버 작업에 적합: 인벤토리 그룹을 통해 여러 서버에 같은 구성을 적용할 수 있다.  
* Agentless: 대상 Linux 서버에 별도 에이전트를 설치하지 않고 주로 SSH로 통신한다.

## 1.1 Ansible의 동작 방식

Ansible은 관리 노드에만 도구를 설치하고 대상 서버에는 별도 에이전트를 설치하지 않는 방식으로 동작한다. Linux 서버는 보통 SSH로 접속하고, Windows 서버는 WinRM을 사용할 수 있다.

기존 Shell Script도 자동화에 사용할 수 있지만, Ansible은 yum, apt, copy, file, lineinfile, systemd 같은 Module을 제공해 작업 의도를 더 명확히 표현한다. 같은 작업을 여러 번 실행해도 이미 원하는 상태라면 변경하지 않는 멱등성을 지향하기 때문에, 서버 초기 구성과 반복 배포 작업에 적합하다.

## 1.2 수동 관리에서 발생하는 문제

여러 서버를 수동으로 관리하면 다음 문제가 자주 발생한다.

* 서버마다 설치된 패키지 버전이나 설정 파일 내용이 달라진다.  
* 작업자가 명령 순서를 다르게 실행해 결과가 달라질 수 있다.  
* 장애 시 어떤 명령을 어느 서버에 적용했는지 추적하기 어렵다.  
* 신규 서버가 추가될 때 기존 서버와 같은 상태로 맞추는 데 시간이 오래 걸린다.

Ansible은 인벤토리(Inventory)에 대상 서버를 그룹화하고, 플레이북(Playbook)에 필요한 작업을 순서대로 정의해 이런 문제를 줄인다.

## 1.3 Terraform과 Ansible 간의 차이점

Ansible과 Terraform은 모두 IaC 도구이며, 두 도구 모두 리소스 배포와 서버 내 작업 실행이 가능하다.

그러나 개인적인 사용 경험으로는 각 도구별로 더 적합한 용도가 다르므로 구분해서 사용하는 것이 좋다.

* Ansible : 다수의 서버 설정 변경, 패키지 설치, 서비스 제어, 명령 실행 등의 서버 구성 관리   
* Terraform : 주로 클라우드 내에서 VM, Network, LB, DB 등 인프라 리소스를 생성 및 관리 

이렇게 구분해서 사용하는 이유는 다음과 같다.

| 구분 | Ansible | Terraform |
| ----- | ----- | ----- |
| **인프라 배포**  | Cloud 모듈을 이용해 VM, Network 등 리소스 생성 가능.  기존 Playbook과 서버 설정 작업을 한 흐름으로 구성 가능  Terraform처럼 인프라 상태를 지속적으로 관리하는 state 개념 부재  Terraform Plan 보다 리소스 변경 예측이 어려움  | 주요 Cloud Provider가 공식 Provider 및 다양한 리소스 모듈 지원  State 기반으로 인프라 상태를 지속적으로 관리 가능  plan으로 변경 내용을 사전에 확인 가능.  |
| **서버 구성 관리**  | 패키지 설치, 서비스 제어, 파일 배포, 명령 실행 등 다양한 서버 구성 관련 모듈이 존재 Task 단위로 실행 결과를 보여주고 조건 분기가 비교적 용이함 | 인프라 생성 과정에서 간단한 초기 설정이나 스크립트 실행 정도는 가능함. remote-exec, local-exec 등을 통해 서버 내부 작업도 가능하지만 스크립트 의존도가 높고 반복적인 서버 설정 관리에는 적합하지 않음.  |

따라서 두 도구 모두 일부 기능을 상호 대체할 수 있지만, **인프라 리소스의 배포와 상태 관리는 Terraform, 서버 내부의 구성 관리와 작업 자동화는 Ansible을 사용하는 것이 각각의 장점을 가장 잘 활용하는 방식이라 생각된다.**

ex) Terraform으로 인프라를 생성한 뒤, 생성된 서버의 내부 구성을 Ansible로 자동화 

## 1.4 멱등성(Idempotency)

멱등성(Idempotency)이란 동일한 작업을 여러 번 실행하더라도 최종 시스템 상태가 동일하게 유지되는 특성을 의미한다.

Ansible은 대부분의 Module에서 대상 서버의 현재 상태를 확인하고, Playbook에 정의된 상태와 다른 경우에만 변경 작업을 수행한다. 따라서 이미 원하는 상태로 구성되어 있다면 동일한 Playbook을 다시 실행하더라도 불필요한 변경을 수행하지 않는다.

예를 들어 다음 Task를 여러 번 실행하더라도 nginx 패키지가 이미 설치되어 있다면 다시 설치하지 않는다.

**\[ nginx 패키지 설치용 Task\]**

```yaml
- name: Install nginx
  ansible.builtin.package:
    name: nginx
    state: present
```

최초 실행 시 패키지가 설치되지 않은 상태라면 결과 출력 시 다음과 같이 changed로 표기된다.

```text
changed: [web-01]
```

이후 동일한 Task를 다시 실행하면 이미 해당 Package가 설치된 상태이므로 다시 설치하지 않고 Task가 완료되며, 결과출력 시 ok로 표기된다.

```text
ok: [web-01]
```

이러한 멱등성을 활용하면 동일한 Playbook을 여러 서버에 반복 실행하거나, 기존 서버와 신규 서버에 동일하게 적용하더라도 필요한 작업만 수행하도록 구성할 수 있다. 이를 통해 서버별 설정 차이를 줄이고 반복적인 운영 작업을 보다 안정적으로 수행할 수 있다.

다만 모든 Task가 자동으로 멱등성을 보장하는 것은 아니다. 특히 shell이나 command 모듈과 같이 명령 자체를 실행하는 Module들은 기본적으로 실행 자체를 변경 작업으로 판단하는 경우가 많다. 

따라서 동일한 기능을 제공하는 전용 Module이 있다면 이를 우선 사용하며, shell/command 등을 사용하는 경우에는 when 등의 실행 조건을 이용하여 불필요한 실행을 방지하고, changed\_when을 사용해 실제 변경 여부가 정확하게 표기되도록 구성하는 것이 좋다.

**\[shell 모듈의 changed\_when 적용 예시\]**

```yaml
- name: Check config
  shell: /usr/local/bin/check_config.sh
  register: result
  changed_when: "'updated' in result.stdout"
```

**\-\> “updated” 라는 결과값이 나오면 변경이 일어난 것으로 간주함**

# 2\. Ansible 사용방법

Ansible은 일반적으로 SSH를 통해 대상 서버에 연결하므로 Linux 서버 관리에 주로 사용되며, Windows 서버의 경우 WinRM을 통해 관리할 수 있다. 본 문서에서는 Linux 환경에서 Ansible을 사용하는 방법을 중심으로 설명한다.

## 2.1 리눅스 환경 내 Ansible 설치

운영 환경에서는 OS별 패키지 관리자를 사용해 Ansible을 설치하고, ansible \--version으로 설치 상태를 확인한다.

**\[각 OS별 Ansible 설치 방법\]**

```bash
# RedHat (Rocky)
dnf install -y ansible-core

# Debian
apt update
apt install -y ansible

# Ansible 버전 확인
ansible --version
```

## 2.2 Ansible Inventory

인벤토리는 Ansible이 어떤 서버를 대상으로 작업할지 정의하는 목록을 정의한 파일을 말한다.

인벤토리 파일 내에서는 그룹 단위로 대상 서버를 관리할 수 있으며, 필요한 작업별로 서버 그룹을 지정해서 사용이 가능하다.

작업 시 Inventory 내의 서버에 SSH를 통해 접근하므로, 가급적 키 파일을 사용하여 접근이 가능하도록 설정하는 것이 권장된다. 

만약 별도 키 파일을 사용하는 경우 기본 설정 파일인 /etc/ansible/ansible.cfg 에서 지정하거나 Inventory 구성 시 별도 명시가 필요하다.

인벤토리 파일의 기본 경로는 /etc/ansible/hosts이지만, 작업 단위별로 inventory.ini 같은 파일을 따로 두고 \-i 옵션으로 지정하는 방식도 가능하다.

**\[ Inventory 파일 구성 예시\]**

```ini
# IP만으로 구성 (SSH 키와 User는 현재 계정의 값을 사용)
[web]
10.0.0.10
10.0.0.20

[db]
10.0.0.30

# IP, User, SSH 키를 별도 지정하여 구성
[web]
web-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
web-02 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>

[db]
db-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
```

인벤토리는 ansible-inventory 명령으로 구조를 확인할 수 있다. 실제 실행 전 어떤 그룹과 호스트가 잡히는지 보는 데 유용하다.

```bash
# JSON 형태로 Inventory 목록을 출력
ansible-inventory -i inventory.ini --list

# Graph(Tree) 형태로 Inventory 목록 출력
ansible-inventory -i inventory.ini --graph
```

## 2.3 Ansible 명령 기본 사용법

플레이북을 작성하지 않고도 ansible 명령을 통해  간단한 일회성 작업이 가능하다.

```bash
# 전체 인벤토리에 Ping 모듈로 연결 확인  #(대상 Host에 Ansible로 접속하여 Module을 실행 가능한지 확인)
ansible all -m ping

# inventory.ini 파일에 등록된 web 그룹에 command 모듈을 사용하여 uptime 명령 실행
ansible web -i inventory.ini -m command -a "uptime"
```

* \-m : 사용할 모듈을 지정하는 옵션  
* \-i : 인벤토리 파일을 별도로 사용하는 경우 사용   
* \-a : 모듈에 전달할 인자를 지정 

# 3\. Ansible-Playbook 

하나의 모듈만 사용하는 경우라면 ansible 명령으로 충분하지만, 대부분의 서버 구성 및 관리 작업은 여러 작업이 동시에 수반되는 경우가 많다. 이때 사용하는 것이 Ansible-Playbook이다. Ansible-Playbook이란 여러 Task를 명시해둔 YAML파일을 뜻하며, 작업 대상 그룹, 변수 지정, 유저 설정 등의 여러 옵션을 하나의 파일에 명시해서 사용한다.

Ansible-Playbook YAML파일에 명시된 Task는 위에서 아래로 순서대로 실행된다.

또한 YAML파일 형식을 사용하므로 들여쓰기에 민감해서 구조를 일관되게 작성해야 한다. 작성 시에는 탭이 아닌 Space로 공백을 사용해야 하며, 탭을 사용하는 경우 Syntax 오류가 발생하므로 주의해야 한다.

**\[Playbook YAML파일 예시 \- nginx 패키지 설치\]**

```yaml
- name: web server baseline
  hosts: web
  remote_user: user1
  become: true
  gather_facts: true
  vars:
    package_name: nginx

  tasks:
    - name: install package
      package:
        name: "{{ package_name }}"
        state: present

    - name: ensure service is running
      service:
        name: nginx
        state: started
        enabled: true
```

**\[Playbook  기본 옵션\]**

| 옵션 | 설명 |
| :---- | :---- |
| hosts | 인벤토리에 정의된 대상 그룹 또는 호스트 |
| remote\_user | 원격 접속에 사용할 계정 |
| become | sudo 같은 권한 상승 사용 여부 |
| gather\_facts | 대상 서버의 OS, CPU, 메모리 등 fact 수집 여부 |
| vars | play 안에서 사용할 변수 |
| tasks | 대상 서버에서 수행할 작업 목록 |

작성된 ansible-playbook YAML파일의 Task를 실행하려면 ansible-playbook 명령을 사용한다.

기존 ansible 명령과 동일하게 \-i 옵션을 통해 인벤토리 파일을 지정 가능하다.

```bash
# 기본 Inventory 파일을 사용해 Ansible-playbook 실행
ansible-playbook example.yml

# Ansible-playbook 실행 시 특정 인벤토리 파일 사용
ansible-playbook -i inventory.ini example.yml
```

**\[ansible-playbook 명령의 주요 옵션\]**

| 옵션 | 용도 |
| :---- | :---- |
| \--syntax-check | 실제 실행 없이 YAML 문법과 플레이북 구조 확인 |
| \--check | 실제 변경 없이 변경 예상 결과 확인 (Dry run) |
| \--diff | 파일 변경 전후 차이 확인, 보통 \--check와 함께 사용 |
| \--list-hosts | 플레이북 실행 대상 호스트 목록 확인 |
| \--list-tasks | 실행될 태스크 목록 확인 |
| \--start-at-task \[TASK\] | 특정 태스크부터 실행 재개 |
| \--step | 태스크별 실행 여부를 물어보며 진행 |
| \--skip-tags \[tag\] | 특정 태그가 붙은 태스크 제외 |

## 3.1 Ansible-Playbook 작업 결과 표기

Ansible-Playbook의 Task 별 실행 결과는 각 Task 별 실행 결과에 따라 별도로 표기되며, 다음과 같은 상태로 표기한다.

| 결과 | 의미 |
| :---- | :---- |
| ok | Task가 정상 완료 되었으며, 대상 상태 변경 없음 |
| changed | Task가 정상 완료 되었으며, 대상 상태 변경이 발생  |
| failed | Task 수행 도중 오류 발생 |
| skipped | 조건문이나 Tag 조건에 따라 Task 실행을 생략 |

**\[실행 결과 출력 예시\]**

```text
PLAY [run command] ************************************************************************************************************************************
TASK [ls scripts] ********************************************************************************************************************************************
changed: [10.0.0.10]
TASK [debug] *************************************************************************************************************************************************
ok: [10.0.0.10] => {
    "msg": [
        []
    ]
}
PLAY RECAP ***************************************************************************************************************************************************
10.0.0.10                : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 3.2 Module과 Task

Module은 패키지 설치, 파일 복사, 서비스 제어, 명령 실행 등 실제 작업을 수행하는 기능 단위를 뜻하며, Ansible은 다양한 기본 모듈을 제공한다.  기본 모듈들은 ansible.builtin.\[모듈\] 형태로 사용하며, 대부분의 기본 모듈들은 **‘ansible.builtin.’** 을 생략하고 모듈명만 사용할 수도 있다.

Task는 플레이북 안에서 하나의 모듈 호출을 설명하는 단위를 뜻하며, 일반적으로 하나의 Task에서는 하나의 모듈만 실행한다. 각 Task 안에서는  작업 이름(name) , Module, 전달할 옵션, 조건문 (when) 등을 함께 지정 가능하다.

**\[주로 사용되는 builtin 모듈 목록\]**

- Shell 모듈은 Shell을 통해 대부분의 명령을 실행할 수 있어 활용 범위가 넓지만, 명령 실행 자체를 변경 작업으로 판단하는 경우가 많고 명령의 멱등성을 Ansible이 자동으로 보장하지 않는다. 따라서 동일한 기능을 제공하는 전용 Module이 있다면 이를 우선 사용하고, Shell 기능이 필요한 경우에만 사용하는 것이 좋다.

| 모듈 | 주요 용도 |
| :---- | :---- |
| ping | 대상 호스트와 Ansible 통신 가능 여부 확인 |
| copy | 관리 노드의 파일을 대상 서버로 전송 |
| fetch | 대상 서버의 파일을 관리 노드로 가져오기 |
| file | 파일, 디렉터리, 권한, 소유자, 심볼릭 링크 관리 |
| lineinfile | 텍스트 파일의 특정 라인 추가 또는 치환 |
| blockinfile | 여러 줄로 된 텍스트 블록 추가 또는 관리 |
| debug | 변수 값이나 실행 결과 출력 |
| shell | Shell 명령 실행, 단 멱등성 보완 필요 |
| service / systemd | 서비스 시작, 중지, 재시작, enable 관리 |
| package | OS 패키지 설치를 공통 인터페이스로 처리 |
| apt / dnf | Debian/Ubuntu 또는 RHEL 계열 패키지 관리 |
| get\_url | URL에서 파일 다운로드 |
| stat | 파일 존재 여부, 속성, 상태 확인 |
| set\_fact | 플레이 실행 중 동적 변수 생성 |

**\[여러 모듈을 사용한 Playbook YAML 작성 예시  \- Bash 스크립트 배포 및 실행\]**

```yaml
- name: copy script file
  hosts: web
  remote_user: sysadm
  become: true
  gather_facts: no
  vars:
    file_nm: test_script.sh

  tasks:
    - name: copy script file 1
      copy:
        src: "scripts/{{ file_nm }}"
        dest: "/home/sysadm/scripts/{{ file_nm }}"
        mode: "0755"
      tags: copy_task

    - name: Run scripts
      shell: |
        bash /home/sysadm/scripts/{{ file_nm }}
      environment:
        LANG: en_US.UTF-8
      tags: run_task
      register: run_results

    - name: debug "Run Scripts"
      debug: var=run_results.stdout_lines
```

## 3.3 변수와 vars\_files

변수는 환경별 차이를 코드 밖으로 분리한다. 간단한 값은 play 안의 vars에 둘 수 있고, 반복 사용하거나 환경별로 나눌 값은 vars\_files로 분리할 수 있다. 다만, vars와 vars\_files에 동일 변수가 있는 경우 vars\_files의 값이 우선된다.

패키지명, 서비스명, 설치 경로처럼 환경에 따라 달라지는 값은 변수 파일로 분리하면 플레이북 본문을 더 단순하게 유지할 수 있으며, 재사용도 용이하다.

**\[vars\_file 구성\]**

```yaml
# vars_file.yaml
package_name: openjdk-25-jre
service_name: nginx.service
```

**\[Playbook 구성\]**

```yaml
- name: install package with vars file
  hosts: web
  become: true
  gather_facts: false
  vars_files:
    - vars_file.yaml
  vars:
    package_name: gzip   # vars_files와 동일 변수의 값을 지정
  tasks:
    - name: debug "package_name"
      debug:
        msg: "{{ package_name }}"

    - name: install package
      apt:
        name: "{{ package_name }}"
        state: present
      register: install_results

    - name: Get service status
      service_facts:

    - name: debug "Get service status"
      debug:
        msg: "{{ ansible_facts.services[service_name].state }}"
```

**\[실행 결과\]**

- vars\_file에 있는 package\_name 변수가 사용됨

```text
PLAY [install package with vars file] ********************************************************************************************

TASK [debug "install package"] ********************************************************************************************
ok: [10.0.0.100] => {
    "msg": "openjdk-25-jre"
}

TASK [install package] ********************************************************************************************
ok: [10.0.0.100]

TASK [Get service status] ********************************************************************************************
ok: [10.0.0.100]

TASK [debug "Get service status"] ********************************************************************************************
ok: [10.0.0.100] => {
    "msg": "running"
}

PLAY RECAP ********************************************************************************************
10.0.0.100                : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 3.4 register와 set\_fact

Ansible-Playbook 실행 도중 이전 Task의 실행 결과를 다음 Task에서 사용하거나 실행 중 확인된 값을 변수로 사용해야 하는 경우가 발생하는데, 이때 register 혹은 set\_fact를 사용한다.

register는 특정 Task의 실행 결과를 변수에 저장하는 기능으로, 저장된 변수에는 모듈에 따라 stdout, stderr, rc 등의 실행 결과가 포함된다. 이는 이후 Task의 debug, when, set\_fact 등에서 활용 가능하다.

set\_fact는 Playbook 실행 도중 새로운 변수를 생성하거나 기존 변수값을 업데이트하는 경우에 주로 사용된다.

**\[register와 set\_fact 사용 예시 \- Nginx 설정 상태 확인\]**

```yaml
- name: Check nginx configuration
  hosts: web
  become: true
  gather_facts: false

  tasks:
    - name: Run nginx config test
      command: nginx -t
      register: nginx_check
      changed_when: false
      failed_when: false # nginx -t가 실패해도 즉시 중단하지 않음

    - name: Set nginx config status
      set_fact:
        nginx_config_valid: "{{ nginx_check.rc == 0 }}"

    - name: Show nginx config check result
      debug:
        msg: "Nginx config valid: {{ nginx_config_valid }}"
```

다음과 같이 register를 사용해서 실행 결과를 저장하고, 이를 set\_fact로 변수화해서 사용하는 등의 활용이 가능하다.

## 3.5 when 조건문 

when은 조건에 따라 태스크 실행 여부를 결정한다. 

ex) OS가 debian 인지 아니면 Redhat 계열인지 확인 후 Task 수행

**\[register/set\_fact/when 조건을 사용한 예시 \- apache2(httpd) 패키지 설치\]**

- Apache 패키지는 Redhat 계열 리눅스에서는 httpd로, Debian 계열에서는 apache2로 설치  
- gather\_facts를 통해 수집된 시스템 정보 변수로 대상별 OS 계열을 구분하고 각 OS 계열별 Task에 when 조건문을 추가   
- 각 OS에 맞춰 적절한 패키지 명이 사용되도록 set\_fact로 변수 지정

```yaml
- name: Install Apache Web Server
  hosts: all
  become: true
  gather_facts: true

  tasks:
    - name: Set Apache package name for RedHat family
      ansible.builtin.set_fact:
        apache_package: httpd
      when: ansible_facts['os_family'] == 'RedHat'

    - name: Set Apache package name for Debian family
      ansible.builtin.set_fact:
        apache_package: apache2
      when: ansible_facts['os_family'] == 'Debian'

    - name: Install Apache package
      ansible.builtin.package:
        name: "{{ apache_package }}"
        state: present
      register: apache_install_result

    - name: Show install result
      ansible.builtin.debug:
        var: apache_install_result

    - name: Start Apache service
      ansible.builtin.service:
        name: "{{ apache_package }}"
        state: started
        enabled: true
      when: apache_install_result is succeeded
```

## 3.6 Handler

Playbook 내에 여러 Task가 존재하고 특정 Task가 실행될 때만 추가적인 Task가 필요하다면 Handler를 사용할 수 있다. 예를 들면 설정 파일 변경 후 서비스를 재시작해줘야 하는 경우에 사용할 수 있다.                                                                                                              

대상 Task에서 Notify를 통해 Handler를 호출 가능하며, 대상 Task가 Changed 인 경우에만 Handler가 실행된다. 

기본적으로 Handler는 해당 Play의 일반 Task들이 끝난 뒤에 실행되며, 만약 동일 Handler가 여러 Task에서 호출되더라도 한 번만 실행된다.

When과 handler 모두 조건에 따른 Task 실행을 제어하나 사용하는 목적이 다르므로 구분하여 사용해야한다. 

* When   
  * Task 실행 전 현재 태스크의 실행 여부를 판단하는 조건문  
  * 조건이 참이면 해당 태스크를 실행하고, 거짓이면 skipped로 생략

  * 주로 이전 태스크 결과 혹은 변수값에 따라 작업을 분기할 때 사용

* Handler  
  * 모든 Task가 완료되고 나서 특정 Task가 Changed 상태인 경우, 추가로 동작하는 별도 Task

  * 변경이 발생했을 때 후처리 작업을 위해 주로 사용됨

**\[Handler 사용 예시 \- 설정 파일이 변경되면 httpd 서비스 재기동\]**

```yaml
tasks:
  - name: Copy Task A
    copy:
      src: a.conf
      dest: /tmp/a.conf
    notify: Restart httpd

  - name: Copy Task B
    copy:
      src: b.conf
      dest: /tmp/b.conf
    notify: Restart httpd

handlers:
  - name: Restart httpd
    ansible.builtin.service:
      name: httpd
      state: restarted
```

**\-\> Copy Task A, B가 모두 Changed라도 ‘Restart httpd’ Handler는 두 Task 완료 후 한 번만 실행**

## 3.7 loop와 with\_items

반복문은 여러 값에 같은 Task를 반복 적용할 때 사용한다. 변수를 리스트 형태로 작성하고 이를 loop에 전달하면 Task 동작 시 각 값이 순서대로 item 변수에 저장되면서 Task가 실행된다.

**\[ 리스트 변수와 loop를 사용한 예시 \- 한 Task 내에서 여러 패키지를 한 번에 설치\]**

```yaml
vars:
  packages:
    - git
    - curl
    - wget

tasks:
  - name: Install packages
    ansible.builtin.package:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
```

만약 리스트가 단순 문자열이 아니라 Dictionary 형태라면 item.name, item.path처럼 필드를 참조 가능하다.

**\[ Dictionary 변수와 loop를 사용한 예시 \- 다수의 유저 생성\]**

```yaml
vars:
  users:
    - name: appuser
      shell: /bin/bash
    - name: deploy
      shell: /bin/bash

tasks:
  - name: Create users
    user:
      name: "{{ item.name }}"
      shell: "{{ item.shell }}"
      state: present
    loop: "{{ users }}"
```

with\_items는 기존 Ansible에서 사용하던 반복 방식으로, 단순 리스트 반복에서는 loop와 유사하게 사용할 수 있다. 

다만 with\_items는 lookup 기반으로 동작하며 리스트를 한 단계 자동으로 펼치는(flatten) 등 약간의 차이가 존재한다.

신규 Playbook에서는 일반적으로 loop 사용을 권장하므로 loop를 사용하는 것이 좋다.

**\[with\_items를 사용한 리스트 변수 처리 예시 \- 여러 패키지 동시 설치\]**

```yaml
- name: Install packages
  package:
    name: "{{ item }}"
    state: present
  with_items:
    - git
    - curl
    - wget
```

## 3.8 Tag

만약 Playbook 내의 모든 Task를 실행하는 것이 아닌 특정 작업만을 실행하거나, 특정 작업을 제외하고 실행해야하는 경우, Tag를 활용할 수 있다. 전체 Playbook을 다시 실행하지 않고 특정 작업만 다시 실행해야하는 경우 유용하게 사용된다.

Playbook의 특정 Task 등에 별도의 Tag를 지정해두면 해당 태그가 지정된 Task만 실행하거나 제외해서 실행할 수 있다. 또한 하나의 Task에 여러 태그를 지정하는 것도 가능하다.

이를 활용하면 install, config, deploy 와 같이 작업 목적별로 태그를 구분해서 선택적으로 실행하는 구조를 만들 수 있다.

**\[ tag 활용 Task 구성 예시 \- httpd 설치 playbook\]**

```yaml
- name: Configure Apache
  hosts: web
  become: true

  tasks:
    - name: Install Apache
      ansible.builtin.package:
        name: httpd
        state: present
      tags:
        - install

    - name: Copy Apache config
      ansible.builtin.copy:
        src: httpd.conf
        dest: /etc/httpd/conf/httpd.conf
      tags:
        - config

    - name: Restart Apache
      ansible.builtin.service:
        name: httpd
        state: restarted
      tags:
        - restart
```

**\[ tag 활용 Task 구성 예시 \- tag 별 실행 방식\]**

```bash
# 특정 Tag만 실행
ansible-playbook web.yml --tags config

# 여러 Tag 실행
ansible-playbook web.yml --tags "config,restart"

# 특정 Tag를 제외 하여 실행
ansible-playbook web.yml --skip-tags restart
```

# 4\. Playbook 구조화 및 재사용 

## 4.1 include\_tasks 활용

하나의 Playbook 내에서 수행되는 작업이 많아질수록, 관리 및 수정이 점점 어려워진다.

따라서 모든 Task를 하나의 파일에 작성해서 사용하기보다, 각 기능 혹은 역할별로 YAML파일을 분리해서 사용하는 것이 관리하기 좋다. 

Include\_tasks를 사용하면 별도 파일에 정의된 Task 목록을 Playbook 실행 중 불러와 실행할 수 있다.

또한 when 등의 조건을 사용하여 환경이나 조건에 따라 필요한 Task파일만 선택적으로 실행하도록 구성도 가능하다.

일반적으로 메인 Playbook에서는 전체 실행 흐름과 공통 변수를 관리하고, 실제 작업은 별도 Task 파일로 분리하여 구성한다.

**\[include\_tasks를 활용한 기능별 Task 분리 구성 예시\]**

```text
playbooks/
├── main.yaml
└── tasks/
    ├── packages.yaml
    ├── users.yaml
    └── service.yaml
```

* Main.yaml  
  *  공통 변수와 Task의  실행 순서를 관리한다.

```yaml
- name: Configure web servers
  hosts: web
  become: true
  gather_facts: true

  vars:
    app_user: appuser
    app_packages:
      - nginx
      - curl

  tasks:
    - name: Include package tasks
      ansible.builtin.include_tasks: tasks/packages.yaml

    - name: Include user tasks
      ansible.builtin.include_tasks: tasks/users.yaml

    - name: Include service tasks
      ansible.builtin.include_tasks: tasks/service.yaml
```

* tasks/packages.yaml  
  * 패키지 설치만 담당

```yaml
- name: install required packages
  package:
    name: "{{ app_packages }}"
    state: present
```

* tasks/users.yaml  
  * 계정과 디렉터리 구성

```yaml
- name: create application user
  user:
    name: "{{ app_user }}"
    state: present

- name: create application directory
  file:
    path: /opt/app
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    mode: "0755"
```

* tasks/service.yaml  
  * 서비스 상태를 관리

```yaml
- name: ensure nginx is enabled and running
  service:
    name: nginx
    state: started
    enabled: true
```

이러한 방식을 사용하면 각 기능별 실행 흐름 파악이 용이하며, 필요한 부분만 수정하거나 재사용하기 쉬운 구조로 Playbook을 관리할 수 있다.

## 4.2 Template

Template은 Jinja2 문법으로 동적 파일이나 메시지를 만든다. OS, 포트, 경로, 서비스명처럼 환경마다 달라지는 값을 변수로 받아 설정 파일을 생성할 때 유용하다.

예를 들어 Nginx 설정 파일을 서버별 변수로 렌더링하려면 templates/nginx.conf.j2를 다음처럼 작성할 수 있다.

**\[ Nginx 용 Jinja2 템플릿 예시\]**

```nginx
server {
    listen {{ nginx_port }};
    server_name {{ inventory_hostname }};

    root {{ document_root }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Template에서 서버별로 다른 변수를 사용 가능하도록 Inventory 파일 내에 변수를 설정한다.

```ini
[web]
web01 ansible_host=10.0.0.100 nginx_port=80 document_root=/var/www/service-a
web02 ansible_host=10.0.0.200 nginx_port=8080 document_root=/var/www/service-b
```

이후 template 파일을 통해 nginx의 config 파일을 배포하고 Handler로 서비스를 재시작한다.

```yaml
- name: Configure nginx
  hosts: web
  become: true

  tasks:
    - name: Deploy nginx config from template
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/conf.d/app.conf
        owner: root
        group: root
        mode: "0644"
      notify: restart nginx

  handlers:
    - name: restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

각 Host 별로 설정된 변수값에 따라 Template으로 배포되는 파일의 내용이 달라진다.

**\[web-1 \- /etc/nginx/conf.d/app.conf \]**

```nginx
server {
    listen 80;
    server_name web01;

    root /var/www/service-a;
}
```

**\[web-2 \- /etc/nginx/conf.d/app.conf \]**

```nginx
server {
    listen 8080;
    server_name web02;

    root /var/www/service-b;
}
```

이와 같이 파일 구조는 동일하지만 서버나 환경에 따라 일부 설정값이 달라지는 경우, Template을 사용하여 제어가 가능하다.

## 4.3 Role 구조

Role은 반복적으로 사용하는 Playbook 구성을 정해진 디렉토리 구조로 묶어 재사용하기 위한 기능이다.  기존 include\_tasks는 하나의 Playbook이 커졌을 때 Task를 여러 파일로 분리해서 관리하기 위한 목적이라면, Role은 Task, 변수, Template, Handler 등을 하나의 디렉토리 구조로 묶어 특정 서버 역할에 필요한 전체 구성을 하나의 단위로서 관리한다.

예를 들어 Nginx 서버 구성을 Role로 만들면 패키지 설치, 설정 파일 배포, 서비스 실행 등의 작업을 Nginx Role 내부에서 관리하고 메인 Playbook에서는 해당 Role만 호출해서 사용이 가능하다.

**\[Nginx 서버 구성을 위한 Role 구성 예시\]**

```text
ansible/
├── main.yaml
├── inventory
└── roles/
    └── nginx/
        ├── defaults/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── tasks/
        │   ├── main.yml
        │   ├── Debian.yml
        │   └── RedHat.yml
        ├── templates/
        │   └── nginx.conf.j2
        └── vars/
            └── main.yml
```

다음과 같이 프로젝트 상위의 main.yaml은 필요한 Role을 호출하여 사용이 가능하다.

```yaml
- name: Configure web servers
  hosts: web
  become: true

  roles:
    - nginx
```

위와 같이 nginx Role을 지정하면 기본적으로 디렉토리 내의 roles/nginx/tasks/main.yml을 실행하게 된다. 이 파일 내에는 실제 Task를 작성하거나 필요한 경우 다른 Task 파일을 호출할 수 있다.

**\[roles/nginx/tasks/main.yml 예시\]**

- OS 계열에 따라 RedHat.yml, Debian.yml 등의 Task 파일을 별도로 실행하도록 구성

```yaml
- name: Include OS specific tasks
  ansible.builtin.include_tasks: "{{ ansible_facts['os_family'] }}.yml"
```

즉 Role을 호출했을 때의 실행 흐름은 다음과 같다.

```text
main.yaml
   ↓
roles:
  - nginx
   ↓
roles/nginx/tasks/main.yml
   ↓
필요한 Task / Handler / Template 실행
```

Role은 반복적으로 사용하는 서버 구성이나 표준화된 설정을 여러 Playbook에서 재사용하는 경우에 유용하다. 다만  단순한 서버 구성 작업이나 동일 구성을 반복해서 적용할 일이 많지 않다면 Role 구조를 적용하거나 Task 분리 작업이 오히려 관리 복잡도를 높일 수 있다.

따라서 Playbook 규모와 반복 사용 여부를 고려하여 필요한 경우에만 구조를 분리하여 사용하는 것이 좋다.

# 5\. 실제 적용 예시: Docker 설치 및 WEB/WAS 구성

다음은 Ansible-playbook을 활용하여 모든 서버에 docker를 설치한 뒤, 각 역할에 맞게 WEB/WAS 서버 구성을 진행하는 예시이다.

## 5.1 서버 및 아키텍처 구성

**\[서버 구성\]**

* WEB  
  * OS : Rocky Linux 10   
  * Nginx 컨테이너를 통한 Web 서버 구성 (Port : 80\)  
  * Nginx Reverse Proxy를 구성하여 WAS 서버로 트래픽 전달  
* WAS  
  * OS : Ubuntu 24.04 LTS  
  * FastAPI 컨테이너를 통한 WAS 서버 구성 (Port : 8080\)  
* 방화벽 설정  
  * Ansible Control Node → WEB/WAS : TCP 22 접근 허용   
  * Client → WEB : TCP 80 접근 허용   
  * WEB → WAS : TCP 8080 접근 허용 

전체 구성은 Docker 설치, FastAPI 배포, Nginx Reverse Proxy 구성의 세 단계로 나누며 각각 별도의 Role로 관리한다. 

**\[ 아키텍처 구성도\]**

```text
Client
  |
  | HTTP : 80
  v
WEB Server(Rocky Linux 10)
Nginx Container
  |
  | Reverse Proxy
  | HTTP : 8080
  v
WAS Server(Ubuntu 24.04 LTS)
FastAPI Container
```

## 5.2 Ansible-Playbook 구성

Playbook은 하나의 파일에 모든 작업을 작성하지 않고 기능별 Role과 환경별 변수를 분리하여 구성한다. 

**\[Ansible-Playbook 구성\]**

* 각 기능별로 별도 Role을 구성  
  * docker\_engine :  WEB/WAS 서버 공통 Docker 설치  
  * fastapi\_app : WAS 서버의 FastAPI 이미지 Build 및 컨테이너 실행

  * nginx\_proxy :  WEB 서버에서 Nginx 컨테이너를 실행하고 WAS 서버로 Reverse Proxy하도록 설정

```text
ansible-web-was
├── collections
│   └── requirements.yml
├── inventories
│   └── example
│       ├── group_vars
│       │   ├── all.yml
│       │   ├── app.yml
│       │   └── web.yml
│       └── hosts.ini
├── main.yaml
└── roles
    ├── docker_engine
    │   ├── defaults
    │   │   └── main.yml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   ├── configure.yml
    │   │   ├── debian.yml
    │   │   ├── main.yml
    │   │   └── redhat.yml
    │   └── templates
    │       └── daemon.json.j2
    ├── fastapi_app
    │   ├── defaults
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── templates
    │       ├── Dockerfile.j2
    │       ├── main.py.j2
    │       └── requirements.txt.j2
    └── nginx_proxy
        ├── defaults
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── templates
            └── default.conf.j2
```

변수는 Role의 defaults/main.yml에 정의된 기본값과 Inventory의 group\_vars에 정의된 공통 및 그룹별 변수 파일을 조합하여 사용한다.

```text
roles/*/defaults/main.yml
            ↓
inventories/example/group_vars/all.yml # 공통 변수
inventories/example/group_vars/app.yml # WAS 전용 변수
inventories/example/group_vars/web.yml # WEB 전용 변수
```

## 5.3 Inventory 구성

WEB과 WAS 서버를 각각 web, app 그룹으로 구분하고 두 그룹을 docker\_targets의 하위 그룹으로 구성한다.

**\[inventories/example/hosts.ini\]**

```ini
[docker_targets:children]
web
app

# ansible_host : Ansible용 Host IP, private_ip : Template 전달용 변수
[web]
web-1 ansible_host=192.168.1.10 private_ip=192.168.1.10

[app]
was-1 ansible_host=192.168.1.20 private_ip=192.168.1.20
```

## 5.4 Main Playbook 구성

실제 실행용 main.yaml에서는 Docker 설치, WAS 구성, WEB 구성 순서로 Role을 호출하면 된다.

**\[main.yaml\]**

```yaml
- name: Install Docker
  hosts: docker_targets
  become: true           # sudo 등을 사용하여 root 권한으로 실행
  any_errors_fatal: true # 호스트 중 하나라도 실패하면, Play 전체 중단
  roles:
    - docker_engine

- name: Deploy FastAPI WAS
  hosts: app
  become: true
  any_errors_fatal: true
  roles:
    - fastapi_app

- name: Deploy Nginx WEB
  hosts: web
  become: true
  any_errors_fatal: true
  roles:
    - nginx_proxy
```

각 Play 내에서 실행되는 동작은 다음과 같다.

```text
1. docker_targets
   - Docker Engine / containerd 설치
          ↓
2. app
   - FastAPI Image Build 및 Container 실행
          ↓
3. web
   - Nginx Reverse Proxy 구성
```

각 Play에 any\_errors\_fatal: true를 설정하여 하나의 대상 서버에서 작업이 실패하면 다음 단계로 진행하지 않도록 구성한다. 예를 들어 FastAPI 상태 확인이 실패하면 WEB 구성이 진행되지 않고 끝난다.

## 5.5 Role \- docker\_engine

docker 설치를 위한 Role로 모든 WEB/WAS 서버에서 실행된다. 

Debian 계열과 Redhat 계열의 Docker 설치 방법이 다르므로 OS별 Task를 분리하고, 대상 서버의 OS에 맞는 Task를 실행하도록 구성한다.

설치 완료 후에는 Template을 사용하여 docker의 daemon.json 설정 파일을 배포하고, containerd 설정을 구성한다. 만약 설정 파일이 변경되었다면 Handler를 호출하여 containerd와 Docker 서비스를 재기동한다.

마지막으로 Docker Engine과 Containerd 설정 및 서비스 상태를 확인하여 정상적으로 구성되었는지 검증을 진행한다.

**\[ docker\_engine Role 동작 방식\]**

```text
docker_targets
↓
OS 확인
┌────┴────┐
Debian　 RedHat
(Ubuntu)　(Rocky)
↓　　　　 ↓
APT　　　 DNF
└────┬────┘
↓
Docker Engine + containerd 설치
↓
Docker / containerd 설정
├─ daemon.json Template 배포
└─ containerd 설정 적용
↓
설정 변경 시 Handler 실행
├─ containerd 재기동
└─ Docker 재기동
↓
서비스 상태 및 설정값 검증
```

## 5.6 Role \- fastapi\_app

FastAPI 기반 WAS 구성을 위한 Role로 app 그룹의 WAS 서버에서 실행된다.

먼저 Template을 사용하여 FastAPI 애플리케이션 실행에 필요한 Dockerfile, requirements.txt, main.py 등의 Build Context를 생성한다.

이후 기존 FastAPI Docker Image의 존재 여부와 Build Context의 변경 여부를 확인하며, 소스가 변경되었거나 이미지가 존재하지 않는 경우에만 Docker Image를 새로 Build한다.

이미지 준비가 완료되면 FastAPI 컨테이너를 실행하고, /health API를 호출하여 애플리케이션이 정상적으로 동작하는지 확인한다. 상태 확인에 실패할 경우 이후 WEB 서버 구성은 진행하지 않는다.

**\[ fastapi\_app Role 동작 방식\]**

```text
app
↓
FastAPI 변수 검증
↓
Template 사용
Build Context 생성
├─ Dockerfile
├─ requirements.txt
└─ app/main.py
↓
Docker Image 존재 및 변경 여부 확인
↓
필요한 경우 Image Build
↓
FastAPI Container 실행
↓
/health 상태 확인
↓
FastAPI 정상 동작 검증
```

※  실제 운영 환경에서 사용 시에는 이미 구성이 완료된 이미지를 Registry를 통해 Pull 하여 사용하는 방식을 사용하는 것이 낫다. Application 소스까지 Jinja2 Template으로 관리하면 실제 애플리케이션 코드와 Ansible Template을 이중으로 관리해야 하므로 관리 복잡도가 증가하기 때문이다.

## 5.7 Role \- nginx\_proxy

Nginx 기반 WEB 서버와 Reverse Proxy 구성을 위한 Role로 web 그룹의 WEB 서버에서 실행된다.

먼저 Inventory의 app 그룹에 등록된 WAS 서버를 확인하고, 각 서버의 내부 IP와 애플리케이션 Port를 이용하여 Nginx가 요청을 전달할 Backend 서버 정보를 구성한다. 이후 Template을 사용하여 해당 정보를 반영한 Nginx 설정 파일을 생성한다. WAS 서버가 여러 대인 경우에는 app 그룹에 등록된 서버들이 자동으로 Backend 대상에 포함되도록 구성한다.

설정 파일 배포가 완료되면 Nginx 컨테이너를 실행한다. 이후 Nginx 설정 파일이 변경된 경우에는 컨테이너를 재생성하여 변경된 설정을 반영한다.

마지막으로 WEB 서버의 80번 Port로 요청을 보내 Nginx Reverse Proxy를 거쳐 FastAPI WAS까지 요청이 정상적으로 전달되고 응답을 받을 수 있는지 확인한다. 정상 응답이 확인되면 WEB/WAS 구성이 완료된다.

**\[ nginx\_proxy Role 동작 방식\]**

```text
web
↓
WEB 변수 및 WAS 서버 정보 검증
↓
WAS 서버의 private_ip 및 Port 확인
↓
Template 사용
Nginx Reverse Proxy 설정 파일 생성
↓
Nginx Container 실행
↓
Template 변경 시 Container 재생성
↓
WEB → WAS 요청 전달 확인
↓
FastAPI 응답 검증
```

## 5.8 실제 구성 결과

**\[WAS 구성 결과\]**

- Docker 설치 완료  
- FastAPI 컨테이너 정상 실행

![][image1]

**\[WEB 구성 결과\]**

- Docker 설치 완료  
- Nginx 컨테이너 정상 실행

![][image2]

**\[브라우저 내 호출 확인\]**

![][image3]

# **마무리**

서버가 몇 대 되지 않을 때는 직접 접속하여 패키지를 설치하고 설정 파일을 수정하는 방식도 충분히 사용할 수 있다. 하지만 관리 대상이 늘어나고 동일한 작업을 여러 서버에 반복해서 적용해야 하는 상황이 많아질수록, 수동 작업은 작업자의 실수나 서버별 설정 차이로 이어지기 쉽다.

특히 신규 서버를 구성하거나 기존 서버의 설정을 일괄 변경할 때마다 동일한 명령을 반복해서 수행하는 방식은 작업 시간뿐만 아니라 작업 결과의 일관성을 유지하는 측면에서도 한계가 있다. 이러한 반복적인 서버 구성과 운영 작업을 사람이 직접 수행하는 대신 코드로 정의하고, 동일한 절차를 필요한 대상에 반복해서 적용하기 위해 Ansible을 사용할 수 있다.

Ansible은 Inventory를 통해 작업 대상을 관리하고 Playbook을 통해 작업 순서를 코드로 남길 수 있기 때문에, 누가 작업하더라도 동일한 절차로 서버를 구성할 수 있다. 또한 멱등성을 고려하여 Playbook을 작성하면 이미 적용된 설정은 유지하면서 필요한 변경만 수행할 수 있어 동일한 작업을 여러 번 실행하는 데 대한 부담도 줄일 수 있다.

결국 Ansible을 사용하는 가장 큰 이유는 단순히 여러 서버에서 명령을 한 번에 실행하기 위해서라기보다, **반복적으로 발생하는 서버 구성과 운영 작업을 표준화하고, 수동 작업에서 발생할 수 있는 실수와 서버별 설정 차이를 줄이며, 동일한 작업을 필요할 때 다시 실행할 수 있는 형태로 관리하기 위해서**라고 볼 수 있다.

인프라 자체의 생성과 상태 관리는 Terraform과 같은 도구를 사용하고, 생성된 서버 내부의 구성과 반복적인 운영 작업은 Ansible로 관리하는 식으로 역할을 나누면 각 도구의 장점을 활용하면서 인프라부터 서버 구성까지 일관된 자동화 체계를 구성할 수 있다.

# 출처

* Ansible 공식 문서   
  * https://docs.ansible.com  
* Terraform 공식 문서   
  * https://developer.hashicorp.com/terraform/docs

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>

[image3]: <data:image/png;base64,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>
