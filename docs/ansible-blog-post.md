# Ansible을 사용한 여러 서버 관리 방법

이 문서는 Ansible 입문 내용을 먼저 다루고, 이어서 여러 서버 운영 자동화를 위한 심화 구성과 실제 Docker 설치 예시를 순차적으로 설명한다.

## 1부. Ansible 입문: 여러 서버 자동화의 기본 구성과 사용 예시


### 개요

서버가 한두 대일 때는 SSH로 접속해 직접 패키지를 설치하고 설정 파일을 수정해도 큰 문제가 없어 보인다. 하지만 서버가 늘어나면 같은 명령을 반복해야 하고, 서버마다 설정이 조금씩 달라지는 문제가 생긴다. Ansible은 이런 반복 작업을 코드로 정리해 여러 서버에 같은 작업을 일관되게 적용하는 자동화 도구다.

이 글은 Ansible을 처음 접하는 사람을 위한 전편이다. 복잡한 Playbook 작성 기법보다는 Ansible로 어떤 일을 할 수 있는지, 기본 구성 요소는 무엇인지, 실제 자동화가 어떤 흐름으로 구성되는지에 초점을 맞춘다.

### Ansible 개념

Ansible은 Python 기반의 오픈소스 Infrastructure as Code(IaC) 도구다. 서버 구성 관리, 애플리케이션 배포, 파일 배포, 서비스 제어, 반복 운영 작업을 코드로 정의하고 여러 대상에 일관되게 적용할 수 있다.

Ansible의 핵심은 "대상 서버가 어떤 상태여야 하는가"를 플레이북에 선언하고, Ansible이 각 서버의 현재 상태를 확인한 뒤 필요한 변경만 적용하도록 만드는 것이다. 그래서 단순 명령 실행 도구라기보다 서버 상태를 표준화하는 구성 관리 도구로 보는 것이 자연스럽다.

### Ansible 특징

Ansible의 주요 특징은 다음과 같다.

- 멱등성(Idempotency): 같은 작업을 반복 실행해도 최종 상태가 같도록 설계한다.
- 모듈 기반 구조: Shell Script에만 의존하지 않고 목적별 모듈로 작업을 표현한다.
- YAML 형식: 플레이북을 사람이 읽기 쉬운 선언형 문법으로 작성한다.
- 대규모 서버 작업에 적합: 인벤토리 그룹을 통해 여러 서버에 같은 구성을 적용할 수 있다.
- 에이전트리스(Agentless): 대상 Linux 서버에 별도 에이전트를 설치하지 않고 주로 SSH로 통신한다.
- 확장성: 변수, 템플릿, 조건문, 반복문, role을 조합해 환경별 차이를 관리할 수 있다.

### Ansible로 할 수 있는 작업

Ansible은 단순 서버 설정 도구를 넘어 여러 운영 자동화에 활용할 수 있다.

- 서버 초기 설정: 사용자 생성, 패키지 설치, 디렉터리 생성, 권한 설정
- 애플리케이션 배포: 설정 파일 배포, 서비스 재시작, 배포 후 상태 확인
- 보안 설정: 파일 권한 변경, 방화벽 설정, 보안 패치 적용
- 클라우드 인프라 관리: AWS, GCP, Azure 리소스 생성 및 설정 자동화
- 컨테이너 환경 구성: Docker, containerd, Kubernetes 사전 구성
- CI/CD 보조 작업: 배포 서버 준비, 릴리스 스크립트 실행, 배포 후 검증
- 운영 점검: 서버 상태 확인, 로그 수집, 특정 파일 존재 여부 확인

즉, Ansible은 “서버에 접속해서 반복해야 하는 작업”을 구조화하는 데 강하다. Terraform이 인프라 프로비저닝에 자주 쓰인다면, Ansible은 생성된 서버의 구성 관리와 운영 작업 자동화에 자주 사용된다.

### Ansible의 기본 구조

Ansible 자동화는 보통 다음 요소로 구성된다.

| 구성 요소 | 역할 |
| --- | --- |
| Control Node | Ansible 명령을 실행하는 관리 서버 또는 작업자 PC |
| Managed Node | Ansible이 작업을 적용할 대상 서버 |
| Inventory | 대상 서버 목록과 그룹 정보 |
| Module | 실제 작업을 수행하는 기능 단위 |
| Task | 모듈을 호출하는 하나의 작업 |
| Variable | 서버나 환경마다 달라지는 값 |
| Template | 변수로 렌더링되는 설정 파일 |
| Handler | 변경이 발생했을 때만 실행되는 후속 작업 |
| Role | 태스크, 변수, 템플릿, 핸들러를 묶은 재사용 단위 |

Ansible은 대상 Linux 서버에 별도 에이전트를 설치하지 않고 주로 SSH로 통신한다. 이 때문에 관리 노드에서 대상 서버로 SSH 접속이 가능해야 하며, 운영 환경에서는 SSH 키와 계정 정보를 안전하게 관리해야 한다.

### 설치와 기본 확인

Ansible은 OS 패키지 관리자로 설치할 수 있다.

```bash
dnf install -y ansible-core
apt update
apt install -y ansible
ansible --version
```

대상 서버 접속 정보는 실제 값 대신 placeholder로 표현하면 다음과 같다.

```bash
ssh <USERNAME>@<SERVER_IP>
```

실제 운영 문서나 Git 저장소에는 IP, 계정, 개인키, 비밀번호, 토큰을 직접 남기지 않는 것이 좋다.

### Inventory 기본 예시

Inventory는 Ansible이 어느 서버를 대상으로 작업할지 알려주는 목록이다. 서버 역할별로 그룹을 나누면 이후 명령 실행 범위를 쉽게 제한할 수 있다.

```ini
[web]
web-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
web-02 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>

[db]
db-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
```

Inventory 구조는 실행 전에 확인할 수 있다.

```bash
ansible-inventory -i inventory.ini --graph
ansible-inventory -i inventory.ini --list
```

이 단계에서는 아직 서버 설정을 바꾸지 않고, Ansible이 대상을 어떻게 인식하는지만 확인한다.

### ad-hoc 명령으로 시작하기

Ansible을 처음 사용할 때는 Playbook을 작성하기 전에 `ansible` 명령으로 간단한 작업을 실행해볼 수 있다. 이를 ad-hoc 명령이라고 부른다.

```bash
ansible all -i inventory.ini -m ping
ansible web -i inventory.ini -m command -a "uptime"
```

`-m`은 사용할 모듈을 지정하고, `-a`는 모듈에 넘길 인자를 지정한다. `ping`은 Ansible 통신 가능 여부를 확인하고, `command`는 대상 서버에서 간단한 명령을 실행한다.

ad-hoc 명령은 빠른 확인에는 좋지만, 반복 운영 작업을 남기고 재사용하기에는 한계가 있다. 같은 작업을 계속 반복해야 한다면 Playbook으로 정리하는 것이 좋다.

### 자주 사용하는 모듈

초기에는 다음 모듈만 알아도 많은 기본 작업을 처리할 수 있다.

| 모듈 | 사용 예 |
| --- | --- |
| `ping` | 대상 서버 연결 확인 |
| `command` | 단순 명령 실행 |
| `shell` | 파이프, 리다이렉션 등 Shell 기능이 필요한 명령 실행 |
| `package` | OS 공통 방식으로 패키지 설치 |
| `apt` / `dnf` | Debian/Ubuntu 또는 RedHat 계열 패키지 설치 |
| `file` | 디렉터리 생성, 권한 변경, 파일 상태 관리 |
| `copy` | 파일 내용을 대상 서버로 복사 |
| `fetch` | 대상 서버의 파일을 관리 노드로 가져오기 |
| `lineinfile` | 텍스트 파일의 특정 라인 추가 또는 치환 |
| `blockinfile` | 여러 줄 텍스트 블록 추가 또는 관리 |
| `template` | Jinja2 템플릿을 설정 파일로 렌더링 |
| `service` / `systemd_service` | 서비스 시작, 중지, 재시작, enable 설정 |
| `get_url` | URL에서 파일 다운로드 |
| `archive` / `unarchive` | 압축 파일 생성 또는 해제 |
| `stat` | 파일 존재 여부와 속성 확인 |
| `debug` | 변수나 실행 결과 출력 |
| `register` | 태스크 실행 결과를 변수로 저장 |
| `set_fact` | 플레이 실행 중 동적 변수 생성 |

주의할 점은 `shell`과 `command`에 너무 의존하지 않는 것이다. 예를 들어 디렉터리를 만들 때는 `shell: mkdir -p /data/app`보다 `file` 모듈을 사용하는 편이 멱등성(Idempotency)을 유지하기 쉽다.

### Playbook 개념과 기본 구조

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


### 실행 전 확인 습관

Ansible은 여러 서버에 동시에 영향을 줄 수 있으므로 실행 전에 항상 대상을 확인하는 습관이 필요하다.

```bash
ansible-playbook -i inventory.ini main.yaml --syntax-check
ansible-playbook -i inventory.ini main.yaml --list-hosts
ansible-playbook -i inventory.ini main.yaml --list-tasks
ansible-playbook -i inventory.ini main.yaml --check --diff
```

그 다음에는 전체 서버가 아니라 일부 서버에 먼저 적용한다.

```bash
ansible-playbook -i inventory.ini main.yaml --limit docker-01
```

문제가 없을 때 대상 그룹 전체로 범위를 넓히는 것이 안전하다.

### 전편에서 기억할 것

Ansible을 처음 배울 때 모든 문법을 한 번에 이해할 필요는 없다. 먼저 다음 흐름을 잡는 것이 중요하다.

- Inventory로 대상 서버를 그룹화한다.
- ad-hoc 명령으로 연결 상태를 확인한다.
- 반복 작업은 task로 정리한다.
- 서버마다 달라지는 값은 변수로 분리한다.
- 설정 파일은 template으로 분리한다.
- 실행 전에는 대상과 변경 예상 결과를 확인한다.

심화 단계에서는 조건문, 반복문, handler, role, task 분리 전략처럼 실제 운영 자동화에 필요한 내용을 더 깊게 다루면 된다.

---

## 2부. Ansible을 사용한 여러 서버 관리 방법 심화


### 개요

1부에서 다룬 기본 구성 요소를 바탕으로, 2부에서는 실제 운영 자동화에서 자주 필요한 변수 파일, 조건문, 반복문, handler, role, task 분리 전략을 다룬다. 기본 명령과 모듈 설명은 앞에서 정리했으므로 여기서는 플레이북을 더 유지보수하기 좋은 형태로 나누는 방법에 집중한다.

### 변수와 vars_files

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

### register와 set_fact

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

### 조건문 when

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

### when과 Handler의 차이

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

### loop와 with_items

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

### 태그로 일부 태스크만 실행하기

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

### Task 파일 분리와 main.yaml 포함 실행 예시

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

### Role 구조

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

### Template 활용 예시

템플릿(Template)은 Jinja2 문법으로 동적 파일이나 메시지를 만든다. OS, 포트, 경로, 서비스명처럼 환경마다 달라지는 값을 변수로 받아 설정 파일을 생성할 때 유용하다.

예를 들어 Nginx 설정 파일을 서버별 변수로 렌더링하려면 `templates/nginx.conf.j2`를 다음처럼 작성할 수 있다.

```jinja
server {
    listen {{ nginx_port }};
    server_name {{ server_name }};

    root {{ document_root }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

이 템플릿은 플레이북에서 변수와 함께 배포한다.

```yaml
vars:
  nginx_port: 80
  server_name: example.internal
  document_root: /usr/share/nginx/html

tasks:
  - name: deploy nginx config from template
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/conf.d/app.conf
      owner: root
      group: root
      mode: "0644"
```

설정 파일 배포 후 서비스 재시작이 필요하다면 앞에서 설명한 handler와 `notify`를 함께 사용하면 된다.

### 여러 서버에 동일 설정 적용 흐름

다중 서버 작업에서는 한 번에 전체 서버를 바꾸기보다 범위를 좁혀 검증한 뒤 넓히는 것이 좋다.

1. `inventory.ini`에서 `web`, `db`, `batch`처럼 역할별 그룹을 나눈다.
2. `ansible-inventory --graph`로 대상 그룹이 의도대로 잡히는지 확인한다.
3. `--syntax-check`, `--list-hosts`, `--list-tasks`로 실행 전 구조를 검토한다.
4. `--check --diff`로 변경 예상 결과를 확인한다.
5. `--limit web-01`처럼 단일 서버에 먼저 적용하고, 문제가 없으면 `--limit web`으로 확장한다.
6. 서비스 재시작은 핸들러로 묶어 변경이 있을 때만 실행한다.

예를 들어 웹 서버 2대에 같은 Nginx 설정을 적용해야 한다면 인벤토리의 `[web]` 그룹에 두 서버를 넣고, `main.yaml`에서 패키지 설치, 사용자 생성, 템플릿 배포, 서비스 시작 태스크를 순서대로 포함하면 된다.

### 운영 환경 사용 시 주의사항

운영 환경에서는 다음 원칙을 지켜야 한다.

- 인벤토리에는 실제 IP, 계정, 비밀번호, 토큰, 개인키 내용을 직접 커밋하지 않는다.
- 변수 파일에는 민감정보가 들어갈 수 있으므로 Ansible Vault 또는 외부 주입 방식을 사용한다.
- `shell` 태스크는 멱등성이 약해지기 쉬우므로 `changed_when`, `creates`, `removes` 같은 조건을 함께 검토한다.
- 여러 서버 전체에 적용하기 전에 `--limit`으로 일부 대상에 먼저 적용한다.
- `--check --diff` 결과를 확인해 의도하지 않은 파일 변경이 없는지 살핀다.
- 서비스 재시작은 핸들러로 묶어 실제 변경이 있을 때만 실행되게 한다.

### Ansible 방식의 한계

Ansible은 대상 서버 접속 권한과 네트워크 연결이 필요하고, 잘못 작성한 플레이북은 여러 서버에 동시에 영향을 줄 수 있다. 또한 모든 작업이 자동으로 멱등성을 보장하는 것은 아니므로 모듈 선택과 조건 처리가 중요하다.

### 실제 적용 예시: Docker 설치와 root 경로 변경

다음은 `task_example` 디렉터리의 구성을 바탕으로 정리한 실제 적용 예시다. 목적은 여러 서버에 Docker Engine을 설치하고, Docker와 containerd의 root 경로를 별도 데이터 디렉터리로 변경한 뒤 결과를 검증하는 것이다.

```text
task_example/
  main.yaml
  var_list.yaml
  tasks/
    install_docker_debian.yaml
    install_docker_redhat.yaml
    configure_docker_root.yaml
    configure_containerd_root.yaml
    verify_docker.yaml
```

핵심은 `main.yaml`이 전체 순서를 관리하고, 실제 작업은 기능별 태스크 파일로 분리한다는 점이다.

```yaml
---
- name: Install Docker Engine and configure custom roots
  hosts: docker_targets
  become: true
  gather_facts: true

  vars_files:
    - var_list.yaml

  pre_tasks:
    - name: validate supported OS family
      assert:
        that:
          - ansible_os_family in ["Debian", "RedHat"]

  tasks:
    - name: include Debian-family Docker installation tasks
      include_tasks: tasks/install_docker_debian.yaml
      when: ansible_os_family == "Debian"

    - name: include RedHat-family Docker installation tasks
      include_tasks: tasks/install_docker_redhat.yaml
      when: ansible_os_family == "RedHat"

    - name: include Docker root configuration tasks
      include_tasks: tasks/configure_docker_root.yaml

    - name: include containerd root configuration tasks
      include_tasks: tasks/configure_containerd_root.yaml

    - name: include Docker verification tasks
      include_tasks: tasks/verify_docker.yaml
```

변수 파일은 운영자가 조정해야 하는 값을 한곳에 모은다.

```yaml
---
docker_version: "28.5.1"
docker_install_latest_when_version_unavailable: true
docker_data_root: "/data/docker"
containerd_root: "/data/containerd"
containerd_state: "/run/containerd"
docker_repo_channel: "stable"
```

설치 태스크는 OS 계열별로 나뉜다. Debian 계열은 `apt`, RedHat 계열은 `dnf`와 `yum_repository`를 사용한다. 두 파일 모두 기존 충돌 패키지를 제거하고, Docker 공식 저장소를 구성한 뒤, 요청한 Docker 버전이 있으면 해당 버전을 설치하고 없으면 설정에 따라 최신 버전으로 fallback한다.

Docker root 설정 태스크는 Docker를 멈춘 뒤 `/etc/docker/daemon.json`에 `data-root`와 로그 옵션을 기록한다.

```yaml
- name: configure Docker daemon data-root
  copy:
    dest: /etc/docker/daemon.json
    owner: root
    group: root
    mode: "0644"
    content: |
      {
        "data-root": "{{ docker_data_root }}",
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "100m",
          "max-file": "3"
        }
      }
```

containerd 설정 태스크는 `/etc/containerd/config.toml`이 없으면 기본 설정을 생성하고, `root`와 `state` 값을 변수 기준으로 치환한다. 이후 systemd daemon을 reload하고 containerd와 Docker를 재시작한다.

마지막 검증 태스크는 `docker version`, `docker info`, `config.toml`의 root/state 값을 확인하고 debug로 출력한다. 이런 검증 태스크를 별도 파일로 분리해 두면 설치 직후 확인 절차를 반복적으로 재사용할 수 있다.

이 예시에서 볼 수 있는 운영 패턴은 세 가지다. 첫째, `pre_tasks`로 지원 가능한 OS 계열을 먼저 검증한다. 둘째, `when`과 `include_tasks`를 함께 사용해 OS별 설치 과정을 분리한다. 셋째, 설치, 설정 변경, 검증을 각각 다른 태스크 파일로 나누어 장애 지점을 추적하기 쉽게 만든다.

### 마무리

Ansible은 인벤토리로 대상을 정의하고, ad-hoc 명령으로 간단히 확인한 뒤, 플레이북으로 작업을 구조화하는 방식으로 접근하면 이해하기 쉽다. 이후 변수 파일, 조건문, 반복문, 태그, 태스크 분리, 역할 구조를 사용해 운영 가능한 형태로 확장하는 것이 핵심이다.

운영에 적용할 때는 민감정보를 분리하고, 대상 범위를 제한하며, 검증 가능한 모듈과 멱등적인 태스크를 우선 사용하는 것이 좋다.
