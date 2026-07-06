# Ansible을 사용한 여러 서버 관리 방법

## 개요

여러 서버를 직접 관리하다 보면 같은 패키지 설치, 설정 파일 배포, 서비스 재시작 작업이 반복된다. 서버 수가 늘어날수록 수동 작업은 누락, 순서 오류, 환경 차이, 작업 이력 부재 같은 문제를 만들기 쉽다.

Ansible은 이런 반복 작업을 코드로 정의해 여러 서버에 동일한 구성을 적용하는 자동화 도구다. 인벤토리, ad-hoc 명령, 플레이북 옵션, 태그, 변수 파일, 조건문, 반복문을 조합하면 단순 명령 실행부터 운영 자동화까지 단계적으로 확장할 수 있다.

## Ansible 개념과 특징

Ansible은 Python 기반의 오픈소스 Infrastructure as Code(IaC) 도구다. 서버 구성 관리, 애플리케이션 배포, 파일 배포, 서비스 제어, 반복 운영 작업을 코드로 정의해 여러 대상에 일관되게 적용할 수 있다.

Ansible의 주요 특징은 다음과 같다.

- 멱등성(Idempotency): 같은 작업을 반복 실행해도 최종 상태가 같도록 설계한다.
- 모듈 기반 구조: Shell Script에만 의존하지 않고 목적별 모듈로 작업을 표현한다.
- YAML 형식: 플레이북을 사람이 읽기 쉬운 선언형 문법으로 작성한다.
- 대규모 서버 작업에 적합: 인벤토리 그룹을 통해 여러 서버에 같은 구성을 적용할 수 있다.
- 에이전트리스(Agentless): 대상 Linux 서버에 별도 에이전트를 설치하지 않고 주로 SSH로 통신한다.

## Ansible을 사용하는 이유

Ansible은 관리 노드에만 도구를 설치하고 대상 서버에는 별도 에이전트를 설치하지 않는 방식으로 동작한다. Linux 서버는 보통 SSH로 접속하고, Windows 서버는 WinRM을 사용할 수 있다.

기존 Shell Script도 자동화에 사용할 수 있지만, Ansible은 `yum`, `apt`, `copy`, `file`, `lineinfile`, `systemd` 같은 모듈(Module)을 제공해 작업 의도를 더 명확히 표현한다. 같은 작업을 여러 번 실행해도 이미 원하는 상태라면 변경하지 않는 멱등성(Idempotency)을 지향하기 때문에, 서버 초기 구성과 반복 배포 작업에 적합하다.

## 수동 관리에서 발생하는 문제

여러 서버를 수동으로 관리하면 다음 문제가 자주 발생한다.

- 서버마다 설치된 패키지 버전이나 설정 파일 내용이 달라진다.
- 작업자가 명령 순서를 다르게 실행해 결과가 달라질 수 있다.
- 장애 시 어떤 명령을 어느 서버에 적용했는지 추적하기 어렵다.
- 신규 서버가 추가될 때 기존 서버와 같은 상태로 맞추는 데 시간이 오래 걸린다.

Ansible은 인벤토리(Inventory)에 대상 서버를 그룹화하고, 플레이북(Playbook)에 필요한 작업을 순서대로 정의해 이런 문제를 줄인다.

## 설치와 접속 준비

운영 환경에서는 OS별 패키지 관리자를 사용해 Ansible을 설치하고, `ansible --version`으로 설치 상태를 확인한다.

```bash
dnf install -y ansible-core
apt update
apt install -y ansible
ansible --version
```

대상 Linux 서버를 관리하려면 관리 노드에서 대상 서버로 SSH 접속이 가능해야 한다. 실제 키, 계정, IP는 직접 남기지 말고 다음처럼 placeholder로 표현한다.

```bash
ssh <USERNAME>@<SERVER_IP>
```

## Inventory 개념과 예시

인벤토리는 Ansible이 어떤 서버를 대상으로 작업할지 정의하는 목록이다. 기본 경로는 `/etc/ansible/hosts`이지만, 작업 단위별로 `inventory.ini` 같은 파일을 따로 두고 `-i` 옵션으로 지정하는 방식이 더 관리하기 쉽다.

```ini
[web]
web-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
web-02 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>

[db]
db-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
```

인벤토리는 `ansible-inventory` 명령으로 구조를 확인할 수 있다. 실제 실행 전 어떤 그룹과 호스트가 잡히는지 보는 데 유용하다.

```bash
ansible-inventory -i inventory.ini --list
ansible-inventory -i inventory.ini --graph
```

## ansible 명령 기본 사용법

`ansible` 명령은 플레이북을 작성하지 않고 간단한 일회성 작업을 실행할 때 사용한다.

```bash
ansible all -i inventory.ini -m ping
ansible web -i inventory.ini -m command -a "uptime"
```

`-m`은 사용할 모듈을 지정하고, `-a`는 모듈에 전달할 인자를 지정한다. `ping`은 대상 서버와 Ansible 통신이 가능한지 확인할 때 사용한다. `command`나 `shell`은 편리하지만 멱등성을 보장하기 어렵기 때문에 운영 작업에서는 목적에 맞는 모듈을 우선 검토해야 한다.

## 작업 결과 표기 이해

Ansible 실행 결과는 서버 상태를 빠르게 파악할 수 있도록 요약된다.

| 결과 | 의미 |
| --- | --- |
| `ok` | 대상 서버가 이미 원하는 상태라 변경하지 않음 |
| `changed` | 대상 서버 상태가 달라 변경을 적용함 |
| `failed` | 오류로 인해 작업이 실패함 |
| `skipped` | 조건문이나 태그 조건에 따라 작업을 건너뜀 |

운영에서는 `changed`가 예상보다 많거나, 특정 서버만 `failed`가 발생하는지 확인해야 한다.

## Playbook 개념과 기본 구조

플레이북은 어떤 서버 그룹에 어떤 작업을 어떤 순서로 적용할지 정의하는 YAML 파일이다. Ansible은 플레이북을 위에서 아래로 순서대로 실행하며, YAML 들여쓰기에 민감하므로 구조를 일관되게 작성해야 한다.

```yaml
---
- name: web server baseline
  hosts: web
  remote_user: <USERNAME>
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

주요 play 내부 옵션은 다음과 같다.

| 옵션 | 설명 |
| --- | --- |
| `hosts` | 인벤토리에 정의된 대상 그룹 또는 호스트 |
| `remote_user` | 원격 접속에 사용할 계정 |
| `become` | sudo 같은 권한 상승 사용 여부 |
| `gather_facts` | 대상 서버의 OS, CPU, 메모리 등 fact 수집 여부 |
| `vars` | play 안에서 사용할 변수 |
| `tasks` | 대상 서버에서 수행할 작업 목록 |

## ansible-playbook 기본 사용법과 옵션

`ansible-playbook`은 여러 태스크를 순서대로 실행할 때 사용한다.

```bash
ansible-playbook -i inventory.ini site.yml --syntax-check
ansible-playbook -i inventory.ini site.yml --list-hosts
ansible-playbook -i inventory.ini site.yml --list-tasks
ansible-playbook -i inventory.ini site.yml --check --diff
ansible-playbook -i inventory.ini site.yml --limit web
```

자주 쓰는 옵션은 다음과 같다.

| 옵션 | 용도 |
| --- | --- |
| `--syntax-check` | 실제 실행 없이 YAML 문법과 플레이북 구조 확인 |
| `--check` | 실제 변경 없이 변경 예상 결과 확인 |
| `--diff` | 파일 변경 전후 차이 확인, 보통 `--check`와 함께 사용 |
| `--list-hosts` | 플레이북 실행 대상 호스트 목록 확인 |
| `--list-tasks` | 실행될 태스크 목록 확인 |
| `--start-at-task` | 특정 태스크부터 실행 재개 |
| `--step` | 태스크별 실행 여부를 물어보며 진행 |
| `--skip-tags` | 특정 태그가 붙은 태스크 제외 |
| `--vault-password-file` | Ansible Vault 비밀번호 파일 지정 |

## Module과 Task

모듈은 실제 작업을 수행하는 Ansible의 기능 단위다. 태스크(Task)는 플레이북 안에서 하나의 모듈 호출을 설명하는 단위다.

자주 사용되는 모듈은 다음과 같다.

| 모듈 | 주요 용도 |
| --- | --- |
| `ping` | 대상 호스트와 Ansible 통신 가능 여부 확인 |
| `copy` | 관리 노드의 파일을 대상 서버로 전송 |
| `fetch` | 대상 서버의 파일을 관리 노드로 가져오기 |
| `file` | 파일, 디렉터리, 권한, 소유자, 심볼릭 링크 관리 |
| `lineinfile` | 텍스트 파일의 특정 라인 추가 또는 치환 |
| `blockinfile` | 여러 줄로 된 텍스트 블록 추가 또는 관리 |
| `debug` | 변수 값이나 실행 결과 출력 |
| `shell` | Shell 명령 실행, 단 멱등성 보완 필요 |
| `service` / `systemd` | 서비스 시작, 중지, 재시작, enable 관리 |
| `package` | OS 패키지 설치를 공통 인터페이스로 처리 |
| `apt` / `dnf` | Debian/Ubuntu 또는 RHEL 계열 패키지 관리 |
| `get_url` | URL에서 파일 다운로드 |
| `archive` / `unarchive` | 압축 파일 생성 또는 해제 |
| `stat` | 파일 존재 여부, 속성, 상태 확인 |
| `register` | 태스크 실행 결과를 변수로 저장 |
| `set_fact` | 플레이 실행 중 동적 변수 생성 |

```yaml
- name: create application directory
  file:
    path: /opt/app
    state: directory
    owner: <USERNAME>
    group: <USERNAME>
    mode: "0755"
```

파일 관리에는 `file`, 패키지 설치에는 `package`, 설정 파일 수정에는 `lineinfile` 또는 `blockinfile`, 서비스 제어에는 `service` 또는 `systemd`를 우선 검토한다. `shell`은 거의 모든 명령을 실행할 수 있지만, 같은 명령이 매번 변경으로 표시될 수 있어 조건 처리가 중요하다.

## 변수와 vars_files

변수(Variable)는 환경별 차이를 코드 밖으로 분리한다. 간단한 값은 play 안의 `vars`에 둘 수 있고, 반복 사용하거나 환경별로 나눌 값은 `vars_files`로 분리할 수 있다.

```text
vars_file.yml
package_name: openjdk-17-jdk
service_name: tomcat
```

```yaml
---
- name: install package with vars file
  hosts: app
  become: true
  gather_facts: false
  vars_files:
    - vars_file.yml

  tasks:
    - name: install package
      apt:
        name: "{{ package_name }}"
        state: present
```

패키지명, 서비스명, 설치 경로처럼 환경에 따라 달라지는 값은 변수 파일로 분리하면 플레이북 본문을 더 단순하게 유지할 수 있다.

## register와 set_fact

`register`는 태스크 실행 결과를 변수에 저장하고, `set_fact`는 플레이북 실행 중 새 변수를 만든다. 예를 들어 OS 확인 결과나 명령 출력값을 저장한 뒤 다음 태스크의 조건문이나 debug 출력에 사용할 수 있다.

```yaml
---
- name: collect command result
  hosts: app
  gather_facts: false

  tasks:
    - name: check os id
      shell: |
        cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/"//g'
      register: os_check
      changed_when: false

    - name: save os id
      set_fact:
        os_id: "{{ os_check.stdout }}"

    - name: print os id
      debug:
        var: os_id
```

## 조건문 when

`when`은 조건에 따라 태스크 실행 여부를 결정한다. OS에 따라 패키지 관리자가 다른 경우 자주 사용한다.

```yaml
---
- name: install package by os
  hosts: app
  become: true
  gather_facts: true
  vars:
    package_name: httpd

  tasks:
    - name: install package on Ubuntu
      apt:
        name: "{{ package_name }}"
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: install package on RHEL family
      dnf:
        name: "{{ package_name }}"
        state: present
      when: ansible_os_family == "RedHat"
```

OS별 설정이 길어지는 경우에는 `when`으로 개별 태스크를 제어하거나, OS별 태스크 파일을 나누고 `include_tasks`로 불러오는 방식으로 정리할 수 있다.

## when과 Handler의 차이

`when`과 handler는 둘 다 태스크 실행을 제어하지만 목적이 다르다.

`when`은 현재 태스크를 실행할지 말지 판단하는 조건문이다. 조건이 참이면 해당 태스크를 실행하고, 거짓이면 `skipped`로 넘어간다. OS 종류, 변수 값, 이전 태스크 결과에 따라 작업을 분기할 때 사용한다.

```yaml
- name: install package on Ubuntu
  apt:
    name: nginx
    state: present
  when: ansible_distribution == "Ubuntu"
```

handler는 어떤 태스크에서 변경이 발생했을 때만 나중에 실행되는 후속 작업이다. 일반적으로 설정 파일을 배포한 뒤 서비스 재시작이 필요할 때 사용한다. 조건 분기보다는 "변경이 있었으니 후처리를 실행한다"는 의미에 가깝다.

```yaml
- name: deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify:
    - restart nginx

handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

정리하면 `when`은 태스크 실행 조건을 판단하고, handler는 변경 발생 이후 필요한 후속 작업을 모아 실행한다. 같은 서비스 재시작이라도 OS별로 실행 여부를 나누려면 `when`, 설정 파일 변경시에만 재시작하려면 handler를 쓰는 것이 자연스럽다.

## loop와 with_items

반복문은 여러 값에 같은 태스크를 적용할 때 사용한다.

```yaml
---
- name: create multiple directories
  hosts: app
  become: true
  vars:
    app_dirs:
      - /opt/app
      - /opt/app/logs
      - /opt/app/data

  tasks:
    - name: create directories
      file:
        path: "{{ item }}"
        state: directory
        mode: "0755"
      loop: "{{ app_dirs }}"
```

리스트가 단순 문자열이 아니라 딕셔너리라면 `item.name`, `item.path`처럼 필드를 참조할 수 있다.

```yaml
vars:
  users:
    - name: appuser
      shell: /bin/bash
    - name: deploy
      shell: /bin/bash
```

## 태그로 일부 태스크만 실행하기

태그(Tag)는 플레이북 일부만 선택적으로 실행하거나 제외할 때 사용한다.

```yaml
- name: set secure file permission
  file:
    path: /etc/security/passwd
    owner: root
    mode: "0400"
  tags:
    - chmod_secpasswd
```

실행 시에는 다음처럼 특정 태그만 실행하거나 제외할 수 있다.

```bash
ansible-playbook -i inventory.ini site.yml --tags chmod_secpasswd
ansible-playbook -i inventory.ini site.yml --skip-tags chmod_secpasswd
```

## Task 파일 분리와 main.yaml 포함 실행 예시

서버 관리 작업이 커지면 모든 태스크를 한 파일에 넣기보다 기능별 파일로 분리하는 것이 좋다. `include_tasks`를 사용하면 패키지 설치, 사용자 생성, 서비스 관리처럼 책임이 다른 작업을 별도 파일로 나누고 `main.yaml`에서 순서대로 불러올 수 있다.

```text
playbooks/
  main.yaml
  tasks/
    packages.yaml
    users.yaml
    service.yaml
```

`main.yaml`은 실행 순서만 관리한다.

```yaml
---
- name: configure multiple web servers
  hosts: web
  become: true
  gather_facts: true

  vars:
    app_user: <USERNAME>
    app_packages:
      - nginx
      - curl

  tasks:
    - name: include package tasks
      include_tasks: tasks/packages.yaml

    - name: include user tasks
      include_tasks: tasks/users.yaml

    - name: include service tasks
      include_tasks: tasks/service.yaml
```

`tasks/packages.yaml`은 패키지 설치만 담당한다.

```yaml
---
- name: install required packages
  package:
    name: "{{ app_packages }}"
    state: present
```

`tasks/users.yaml`은 계정과 디렉터리 구성을 담당한다.

```yaml
---
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

`tasks/service.yaml`은 서비스 상태를 관리한다.

```yaml
---
- name: ensure nginx is enabled and running
  service:
    name: nginx
    state: started
    enabled: true
```

이 방식은 여러 서버에 같은 작업을 적용하면서도 파일별 책임이 분명하다. 패키지, 사용자, 서비스, 배포 작업을 분리하면 장애 원인을 찾기 쉽고, 특정 작업만 재사용하기도 편하다.

## Role 구조

역할(Role)은 반복되는 플레이북 구성을 디렉터리 단위로 재사용하기 위한 구조다. 태스크, 변수, 템플릿, 핸들러를 정해진 디렉터리 구조로 묶어 서버 유형별 표준 구성을 만들 수 있다.

```text
role/nginx/
  defaults/main.yml
  handlers/main.yml
  meta/main.yml
  tasks/main.yml
  tasks/Ubuntu.yml
  tasks/RedHat.yml
  templates/ins_chk.j2
  tests/inventory
  tests/test.yml
  vars/main.yml
```

`tasks/main.yml`은 역할의 기본 진입점이고, `handlers/main.yml`은 변경 발생 후 실행할 후속 작업을 둔다. `defaults/main.yml`과 `vars/main.yml`은 역할에서 사용할 기본값과 변수를 관리한다.

## Template과 Handler

템플릿(Template)은 Jinja2 문법으로 동적 파일이나 메시지를 만든다. OS, 포트, 경로, 서비스명처럼 환경마다 달라지는 값을 변수로 받아 설정 파일을 생성할 때 유용하다.

핸들러(Handler)는 변경이 발생했을 때만 실행되는 후속 작업이다.

```yaml
- name: deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify:
    - restart nginx

handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

설정 파일이 바뀌지 않았다면 핸들러가 실행되지 않으므로 불필요한 서비스 재시작을 줄일 수 있다.

## 여러 서버에 동일 설정 적용 흐름

다중 서버 작업에서는 한 번에 전체 서버를 바꾸기보다 범위를 좁혀 검증한 뒤 넓히는 것이 좋다.

1. `inventory.ini`에서 `web`, `db`, `batch`처럼 역할별 그룹을 나눈다.
2. `ansible-inventory --graph`로 대상 그룹이 의도대로 잡히는지 확인한다.
3. `--syntax-check`, `--list-hosts`, `--list-tasks`로 실행 전 구조를 검토한다.
4. `--check --diff`로 변경 예상 결과를 확인한다.
5. `--limit web-01`처럼 단일 서버에 먼저 적용하고, 문제가 없으면 `--limit web`으로 확장한다.
6. 서비스 재시작은 핸들러로 묶어 변경이 있을 때만 실행한다.

예를 들어 웹 서버 2대에 같은 Nginx 설정을 적용해야 한다면 인벤토리의 `[web]` 그룹에 두 서버를 넣고, `main.yaml`에서 패키지 설치, 사용자 생성, 템플릿 배포, 서비스 시작 태스크를 순서대로 포함하면 된다.

## 운영 환경 사용 시 주의사항

운영 환경에서는 다음 원칙을 지켜야 한다.

- 인벤토리에는 실제 IP, 계정, 비밀번호, 토큰, 개인키 내용을 직접 커밋하지 않는다.
- 변수 파일에는 민감정보가 들어갈 수 있으므로 Ansible Vault 또는 외부 주입 방식을 사용한다.
- `shell` 태스크는 멱등성이 약해지기 쉬우므로 `changed_when`, `creates`, `removes` 같은 조건을 함께 검토한다.
- 여러 서버 전체에 적용하기 전에 `--limit`으로 일부 대상에 먼저 적용한다.
- `--check --diff` 결과를 확인해 의도하지 않은 파일 변경이 없는지 살핀다.
- 서비스 재시작은 핸들러로 묶어 실제 변경이 있을 때만 실행되게 한다.

## Ansible 방식의 장점과 한계

Ansible의 장점은 진입 장벽이 낮고, YAML로 서버 상태를 설명하듯 표현할 수 있으며, 에이전트 없이 여러 서버를 관리할 수 있다는 점이다. 역할을 사용하면 서버 유형별 표준 구성을 재사용하기도 쉽다.

반면 대상 서버 접속 권한과 네트워크 연결이 필요하고, 잘못 작성한 플레이북은 여러 서버에 동시에 영향을 줄 수 있다. 또한 모든 작업이 자동으로 멱등성을 보장하는 것은 아니므로 모듈 선택과 조건 처리가 중요하다.

## 마무리

Ansible은 인벤토리로 대상을 정의하고, ad-hoc 명령으로 간단히 확인한 뒤, 플레이북으로 작업을 구조화하는 방식으로 접근하면 이해하기 쉽다. 이후 변수 파일, 조건문, 반복문, 태그, 태스크 분리, 역할 구조를 사용해 운영 가능한 형태로 확장하는 것이 핵심이다.

운영에 적용할 때는 민감정보를 분리하고, 대상 범위를 제한하며, 검증 가능한 모듈과 멱등적인 태스크를 우선 사용하는 것이 좋다.
