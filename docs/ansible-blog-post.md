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
- 에이전트리스/데몬리스(Agentless/Daemonless): 대상 서버에 별도 에이전트나 상시 실행 데몬을 설치하지 않고, Ansible을 실행할 Control Node에서 SSH로 접속해 작업을 수행한다.
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

Ansible은 대상 Linux 서버에 별도 에이전트나 데몬을 설치하지 않고 주로 SSH로 통신한다. 따라서 실제 Ansible 패키지는 명령을 실행할 Control Node, 즉 관리 서버나 작업자 PC에 설치하면 된다. Managed Node에는 SSH 접속 권한과 작업에 필요한 Python 실행 환경이 준비되어 있어야 하며, 운영 환경에서는 SSH 키와 계정 정보를 안전하게 관리해야 한다.

### 설치와 기본 확인

Ansible은 OS 패키지 관리자로 설치할 수 있다.

```bash
# RedHat 계열에서는 ansible-core 패키지를 설치한다.
dnf install -y ansible-core

# Debian/Ubuntu 계열에서는 패키지 목록 갱신 후 ansible을 설치한다.
apt update
apt install -y ansible

# 설치된 Ansible 버전과 설정 파일 경로를 확인한다.
ansible --version
```

대상 서버 접속 정보는 실제 값 대신 placeholder로 표현하면 다음과 같다.

```bash
# 관리 노드에서 대상 서버로 SSH 접속이 되는지 먼저 확인한다.
ssh <USERNAME>@<SERVER_IP>
```

실제 운영 문서나 Git 저장소에는 IP, 계정, 개인키, 비밀번호, 토큰을 직접 남기지 않는 것이 좋다.

### 기본 설정 디렉터리와 파일

Linux 패키지로 Ansible을 설치하면 일반적으로 `/etc/ansible/` 디렉터리가 생성된다. 이 디렉터리에는 전역 설정 파일인 `ansible.cfg`와 기본 Inventory 파일인 `hosts`가 위치한다.

```text
/etc/ansible/
├── ansible.cfg
└── hosts
```

`ansible.cfg`는 Ansible 실행 옵션의 기본값을 정의하는 설정 파일이다. 예를 들어 기본 Inventory 경로, SSH host key 확인 여부, retry 파일 생성 여부, 기본 remote user 등을 지정할 수 있다.

```ini
[defaults]
# -i 옵션을 생략했을 때 사용할 기본 Inventory 파일
inventory = /etc/ansible/hosts

# 테스트 환경에서는 편하지만 운영에서는 신중히 사용한다.
host_key_checking = False

# 실패한 호스트 목록을 .retry 파일로 남기지 않는다.
retry_files_enabled = False
remote_user = <USERNAME>

[privilege_escalation]
# sudo 권한 상승을 기본값으로 사용한다.
become = True
become_method = sudo
```

`/etc/ansible/hosts`는 `-i` 옵션을 생략했을 때 사용되는 기본 Inventory다. 간단한 테스트 환경에서는 사용할 수 있지만, 프로젝트별 자동화에서는 저장소 안에 `inventory.ini` 또는 환경별 Inventory 파일을 따로 두고 `-i`로 명시하는 편이 관리하기 쉽다.

```ini
[web]
# web 그룹에 속한 서버 목록
web-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME>

[db]
# db 그룹에 속한 서버 목록
db-01 ansible_host=<SERVER_IP> ansible_user=<USERNAME>
```

설정 파일은 현재 디렉터리의 `ansible.cfg`, 사용자 홈의 `~/.ansible.cfg`, `/etc/ansible/ansible.cfg` 순서로 적용될 수 있다. 따라서 팀 프로젝트에서는 저장소 루트에 필요한 설정만 담은 `ansible.cfg`를 두고, 전역 설정에 의존하지 않는 방식이 안전하다.

### Inventory 기본 예시

Inventory는 Ansible이 어느 서버를 대상으로 작업할지 알려주는 목록이다. 서버 역할별로 그룹을 나누면 이후 명령 실행 범위를 쉽게 제한할 수 있다.

Inventory는 기본 파일인 `/etc/ansible/hosts`만 사용해야 하는 것은 아니다. 프로젝트마다 `inventory.ini`, `inventory-dev.ini`, `inventory-prod.ini`처럼 별도 파일을 만들고 실행 시 `-i` 옵션으로 지정할 수 있다. 이 방식은 환경별 서버 목록을 분리하기 쉽고, 전역 설정에 의존하지 않아 협업에 더 적합하다.

```bash
# 프로젝트 디렉터리의 inventory.ini 파일을 명시적으로 사용한다.
ansible all -i inventory.ini -m ping
```

가장 단순한 Inventory는 서버명과 IP만으로 구성할 수 있다.

```ini
[web]
web-01 ansible_host=<WEB_SERVER_IP>
web-02 ansible_host=<WEB_SERVER_IP>

[db]
db-01 ansible_host=<DB_SERVER_IP>
```

이 경우 접속 계정과 SSH 키는 현재 쉘 사용자, SSH 기본 설정(`~/.ssh/config`), `ansible.cfg`, 실행 옵션 등에 의존한다. 개인 테스트 환경에서는 간단하지만, 실행하는 사람마다 기본 계정이나 키가 다르면 결과가 달라질 수 있다.

접속 정보를 Inventory에 명시하면 대상 서버별 사용자와 키 파일을 더 분명하게 관리할 수 있다.

```ini
[web]
web-01 ansible_host=<WEB_SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
web-02 ansible_host=<WEB_SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>

[db]
db-01 ansible_host=<DB_SERVER_IP> ansible_user=<USERNAME> ansible_ssh_private_key_file=<PRIVATE_KEY_PATH>
```

`ansible_host`는 실제 접속할 IP 또는 DNS 이름이고, 왼쪽의 `web-01`, `db-01`은 Ansible 안에서 사용할 호스트 별칭이다. `ansible_user`와 `ansible_ssh_private_key_file`을 지정하면 실행자의 로컬 SSH 기본값과 무관하게 같은 접속 방식으로 실행할 수 있다. 다만 개인키 경로나 계정 정보가 민감할 수 있으므로 공개 저장소에는 실제 값을 직접 커밋하지 않는다.

Inventory 구조는 실행 전에 확인할 수 있다.

```bash
# Inventory 그룹 구조를 트리 형태로 확인한다.
$ ansible-inventory -i inventory.ini --graph
@all:
  |--@db:
  |  |--db-01
  |--@ungrouped:
  |--@web:
  |  |--web-01
  |  |--web-02


# Inventory를 JSON 형태로 펼쳐서 확인한다.
$ ansible-inventory -i inventory.ini --list
{
    "_meta": {
        "hostvars": {
            "db-01": {
                "ansible_host": "10.0.0.30"
            },
            "web-01": {
                "ansible_host": "10.0.0.10"
            },
            "web-02": {
                "ansible_host": "10.0.0.20"
            }
        }
    },
    "all": {
        "children": [
            "db",
            "ungrouped",
            "web"
        ]
    },
    "db": {
        "hosts": [
            "db-01"
        ]
    },
    "web": {
        "hosts": [
            "web-01",
            "web-02"
        ]
    }
}

```

이 단계에서는 아직 서버 설정을 바꾸지 않고, Ansible이 대상을 어떻게 인식하는지만 확인한다.

### ad-hoc 명령으로 시작하기

Ansible을 처음 사용할 때는 Playbook을 작성하기 전에 `ansible` 명령으로 간단한 작업을 실행해볼 수 있다. 이를 ad-hoc 명령이라고 부른다.

```bash
# all 그룹 전체에 Ansible 연결 가능 여부를 확인한다.
$ ansible all -i inventory.ini -m ping
web-01 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
db-01 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
web-02 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}


# web 그룹에 uptime 명령을 실행한다.
$ ansible web -i inventory.ini -m command -a "uptime"
web-01 | CHANGED | rc=0 >>
 17:02:21 up 3 days,  3:24,  1 user,  load average: 0.00, 0.03, 0.04
web-02 | CHANGED | rc=0 >>
 17:02:21 up 2 days, 47 min,  1 user,  load average: 0.00, 0.03, 0.02

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
  # Inventory의 web 그룹을 대상으로 실행한다.
  hosts: web
  remote_user: <USERNAME>
  become: true
  gather_facts: true

  vars:
    package_name: nginx

  tasks:
    # package 모듈은 OS별 패키지 관리자를 추상화한다.
    - name: install package
      package:
        name: "{{ package_name }}"
        state: present

    # 서비스가 실행 중이고 부팅 시 자동 시작되도록 유지한다.
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

### Ansible에서의 멱등성 예시

멱등성은 같은 작업을 여러 번 실행해도 최종 상태가 같고, 이미 원하는 상태라면 불필요한 변경을 만들지 않는 성질이다. Ansible의 `file`, `package`, `template`, `service` 같은 모듈은 대상 상태를 확인한 뒤 필요한 경우에만 `changed`를 반환하도록 설계되어 있다.

예를 들어 애플리케이션 디렉터리를 만들 때는 다음처럼 `file` 모듈로 원하는 상태를 선언하는 방식이 좋다.

```yaml
- name: ensure application directory exists
  file:
    path: /data/app
    state: directory
    owner: <USERNAME>
    group: <USERNAME>
    mode: "0755"
```

디렉터리가 이미 존재하고 소유자와 권한도 같다면 이 태스크는 `ok`로 끝난다. 반대로 디렉터리가 없거나 권한이 다르면 필요한 변경만 수행하고 `changed`로 표시된다.

같은 작업을 `shell`로 작성하면 실행 결과는 성공하더라도 실제 변경 여부를 Ansible이 정확히 판단하기 어렵다.

```yaml
- name: create application directory with shell
  shell: mkdir -p /data/app
```

부득이하게 명령 실행 모듈을 사용해야 한다면 `creates`, `removes`, `changed_when` 같은 조건을 함께 사용해 변경 여부를 명확히 제어한다.

```yaml
- name: initialize marker file only once
  shell: touch /data/app/.initialized
  args:
    creates: /data/app/.initialized

- name: check docker version without marking changed
  command: docker version
  register: docker_version_result
  changed_when: false
```

### 실행 전 확인 습관

Ansible은 여러 서버에 동시에 영향을 줄 수 있으므로 실행 전에 항상 대상을 확인하는 습관이 필요하다.

```bash
# 플레이북 문법과 모듈 옵션 오류를 실행 전에 확인한다.
$ ansible-playbook -i inventory.ini main.yaml --syntax-check
.....
The offending line appears to be:

      loop_control:
    loop_var: user
    ^ here          # -> 오류가 있는 경우 해당 부분을 표기해줌

# 실제 실행 대상 호스트가 어디인지 확인한다.
$ ansible-playbook -i inventory.ini main.yaml --list-hosts
playbook: main.yaml

  play #1 (web): ping test      TAGS: []
    pattern: ['web']
    hosts (2):
      web-02
      web-01

# 실행될 task 목록과 순서를 확인한다.
$ ansible-playbook -i inventory.ini main.yaml --list-tasks
playbook: main.yaml

  play #1 (web): web server baseline    TAGS: []
    tasks:
      install package   TAGS: []
      ensure service is running TAGS: []


# dry-run 결과와 함께 파일 변경 diff를 확인한다.
$ ansible-playbook -i inventory.ini main.yaml --check --diff

PLAY [web server baseline] ***********************************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************************************
ok: [web-01]
ok: [web-02]

TASK [install package] ***************************************************************************************************************************************
ok: [web-01]
ok: [web-02]

TASK [ensure service is running] *****************************************************************************************************************************
ok: [web-01]
ok: [web-02]

PLAY RECAP ***************************************************************************************************************************************************
web-01                     : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
web-02                     : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

`--check`는 실제 서버를 변경하지 않고 어떤 태스크가 `changed`가 될지 미리 확인하는 dry-run 옵션이다. 단, 모든 모듈이 check mode를 완벽하게 지원하는 것은 아니므로 운영 반영 전에는 `--limit`으로 일부 서버에 먼저 적용해 결과를 확인하는 편이 안전하다. `--diff`는 `template`, `copy`, `lineinfile`처럼 파일 내용을 바꾸는 태스크에서 변경 전후 차이를 확인할 때 유용하다.

그 다음에는 전체 서버가 아니라 일부 서버에 먼저 적용한다.

```bash
ansible-playbook -i inventory.ini main.yaml --limit docker-01
```

문제가 없을 때 대상 그룹 전체로 범위를 넓히는 것이 안전하다.

운영 환경에서는 다음 원칙을 함께 지켜야 한다.

- 인벤토리에는 실제 IP, 계정, 비밀번호, 토큰, 개인키 내용을 직접 커밋하지 않는다.
- 변수 파일에는 민감정보가 들어갈 수 있으므로 Ansible Vault 또는 외부 주입 방식을 사용한다.
- 여러 서버 전체에 적용하기 전에 `--limit`으로 일부 대상에 먼저 적용한다.
- `--check --diff` 결과를 확인해 의도하지 않은 파일 변경이 없는지 살핀다.

### 실행 로그 출력 옵션

Ansible 실행 결과가 부족하게 느껴질 때는 verbosity 옵션을 붙여 로그 상세도를 높인다. 기본 실행은 요약 중심이고, `-v`를 추가할수록 접속 과정, 모듈 실행 결과, SSH 디버그 정보가 더 많이 출력된다.

| 옵션 | 용도 |
| --- | --- |
| `-v` | 기본보다 자세한 실행 결과 확인 |
| `-vv` | 태스크 실행 결과와 일부 모듈 반환값 확인 |
| `-vvv` | SSH 연결, 원격 명령 실행 과정까지 확인 |
| `-vvvv` | 연결 문제를 추적할 때 사용하는 매우 상세한 디버그 출력 |

```bash
ansible-playbook -i inventory.ini main.yaml -v
ansible-playbook -i inventory.ini main.yaml --limit docker-01 -vv
ansible-playbook -i inventory.ini main.yaml --check --diff -vv
```

평소에는 기본 출력이나 `-v` 정도로 충분하다. 접속 실패, 권한 상승 실패, 변수 값 확인처럼 원인을 좁혀야 할 때만 `-vvv` 이상을 사용하는 것이 로그를 읽기 쉽다.

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

```yaml
# vars_file.yml
# 환경별로 달라질 수 있는 값을 플레이북 밖으로 분리한다.
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
    # 위에서 분리한 변수 파일을 play에 불러온다.
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
      # 명령 실행 결과를 os_check 변수에 저장한다.
      register: os_check
      # 조회 목적의 명령이므로 changed로 표시하지 않는다.
      changed_when: false

    - name: save os id
      set_fact:
        # register 결과 중 표준 출력(stdout)만 새 변수로 저장한다.
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
      # Ubuntu일 때만 apt 태스크를 실행한다.
      when: ansible_distribution == "Ubuntu"

    - name: install package on RHEL family
      dnf:
        name: "{{ package_name }}"
        state: present
      # RedHat 계열일 때만 dnf 태스크를 실행한다.
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
  # 조건이 거짓이면 이 태스크는 skipped가 된다.
  when: ansible_distribution == "Ubuntu"
```

handler는 어떤 태스크에서 변경이 발생했을 때만 나중에 실행되는 후속 작업이다. 일반적으로 설정 파일을 배포한 뒤 서비스 재시작이 필요할 때 사용한다. 조건 분기보다는 "변경이 있었으니 후처리를 실행한다"는 의미에 가깝다.

```yaml
- name: deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  # 템플릿 내용이 바뀐 경우에만 handler를 호출한다.
  notify:
    - restart nginx

handlers:
  # notify를 받은 경우 play의 마지막 단계에서 한 번 실행된다.
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
        # loop의 현재 값을 item으로 참조한다.
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

기존 예제에서 `with_items`를 볼 수도 있지만, 최신 플레이북에서는 같은 목적에 `loop`를 사용하는 방식이 더 명확하다.

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
# chmod_secpasswd 태그가 붙은 태스크만 실행한다.
ansible-playbook -i inventory.ini site.yml --tags chmod_secpasswd

# chmod_secpasswd 태그가 붙은 태스크를 제외하고 실행한다.
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
      # 패키지 설치 작업을 별도 파일에서 불러온다.
      include_tasks: tasks/packages.yaml

    - name: include user tasks
      # 사용자와 디렉터리 생성 작업을 별도 파일에서 불러온다.
      include_tasks: tasks/users.yaml

    - name: include service tasks
      # 서비스 상태 관리 작업을 별도 파일에서 불러온다.
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

다중 서버에 동일 설정을 적용할 때는 인벤토리에서 `web`, `db`, `batch`처럼 역할별 그룹을 나누고, `main.yaml`에서 공통 태스크를 순서대로 포함한다. 예를 들어 웹 서버 2대에 같은 Nginx 설정을 적용해야 한다면 `[web]` 그룹에 두 서버를 넣고, 패키지 설치, 사용자 생성, 템플릿 배포, 서비스 시작 태스크를 분리해 포함하면 된다.

실제 반영은 한 번에 전체 그룹에 실행하지 않고 `--limit web-01`처럼 단일 서버에서 먼저 검증한 뒤, 문제가 없을 때 `--limit web`으로 확장한다. 서비스 재시작은 handler로 묶어 설정 변경이 있을 때만 실행되게 하는 것이 좋다.

### Role 구조

`include_tasks`로 파일을 나누는 방식이 커지면 다음 단계로 role을 사용할 수 있다. 역할(Role)은 반복되는 플레이북 구성을 디렉터리 단위로 재사용하기 위한 구조다. 보통 하나의 `roles/` 디렉터리 아래에 `docker`, `nginx`, `node_exporter`처럼 목적별 role을 나누고, 플레이북에서 필요한 role을 조합해 호출한다.

```text
playbooks/
├── site.yaml
├── inventory.ini
└── roles/
    ├── docker/
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   ├── tasks/
    │   │   ├── main.yml
    │   │   ├── Debian.yml
    │   │   └── RedHat.yml
    │   └── templates/
    │       └── daemon.json.j2
    ├── nginx/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   └── templates/
    │       └── nginx.conf.j2
    └── node_exporter/
        ├── defaults/
        │   └── main.yml
        └── tasks/
            └── main.yml
```

`tasks/main.yml`은 각 role의 기본 진입점이고, `handlers/main.yml`은 변경 발생 후 실행할 후속 작업을 둔다. `defaults/main.yml`은 role 사용자가 덮어쓸 수 있는 기본 변수를 관리하고, `templates/`는 role 안에서 사용할 Jinja2 템플릿을 둔다.

플레이북에서는 다음처럼 필요한 role을 순서대로 호출한다.

```yaml
---
- name: configure web monitoring servers
  hosts: web
  become: true

  roles:
    # 공통 런타임을 먼저 설치한다.
    - docker

    # 웹 서버 설정을 적용한다.
    - nginx

    # 모니터링 에이전트를 설치한다.
    - node_exporter
```

이렇게 구성하면 Docker 설치 로직은 `docker` role에, 웹 서버 설정은 `nginx` role에, 모니터링 구성은 `node_exporter` role에 각각 분리된다. 같은 role을 다른 플레이북에서도 재사용할 수 있고, 서버 유형별로 필요한 role 조합만 바꿔 적용할 수 있다.

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
  templates/
    daemon.json.j2
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
          # 지원하지 않는 OS에서는 본 작업을 시작하지 않는다.
          - ansible_os_family in ["Debian", "RedHat"]

  tasks:
    - name: include Debian-family Docker installation tasks
      # Debian/Ubuntu 계열 설치 절차만 포함한다.
      include_tasks: tasks/install_docker_debian.yaml
      when: ansible_os_family == "Debian"

    - name: include RedHat-family Docker installation tasks
      # RHEL/CentOS/Rocky 계열 설치 절차만 포함한다.
      include_tasks: tasks/install_docker_redhat.yaml
      when: ansible_os_family == "RedHat"

    - name: include Docker root configuration tasks
      # Docker data-root 설정을 공통으로 적용한다.
      include_tasks: tasks/configure_docker_root.yaml

    - name: include containerd root configuration tasks
      # containerd root/state 설정을 공통으로 적용한다.
      include_tasks: tasks/configure_containerd_root.yaml

    - name: include Docker verification tasks
      # 설치와 root 경로 변경 결과를 확인한다.
      include_tasks: tasks/verify_docker.yaml
```

변수 파일은 운영자가 조정해야 하는 값을 한곳에 모은다.

```yaml
---
# 설치할 Docker 버전과 fallback 정책
docker_version: "28.5.1"
docker_install_latest_when_version_unavailable: true

# Docker와 containerd 데이터를 저장할 경로
docker_data_root: "/data/docker"
containerd_root: "/data/containerd"
containerd_state: "/run/containerd"

# Docker 공식 저장소 채널
docker_repo_channel: "stable"
```

설치 태스크는 OS 계열별로 나뉜다. Debian 계열은 `apt`, RedHat 계열은 `dnf`와 `yum_repository`를 사용한다. 두 파일 모두 기존 충돌 패키지를 제거하고, Docker 공식 저장소를 구성한 뒤, 요청한 Docker 버전이 있으면 해당 버전을 설치하고 없으면 설정에 따라 최신 버전으로 fallback한다.

Docker root 설정 태스크는 Docker를 멈춘 뒤 `/etc/docker/daemon.json`을 Jinja2 템플릿으로 렌더링한다. 설정 파일 내용을 태스크에 직접 쓰지 않고 `templates/daemon.json.j2`로 분리하면 Docker root 경로나 로그 옵션이 바뀌어도 템플릿만 관리하면 된다.

```yaml
- name: configure Docker daemon data-root
  template:
    # templates/daemon.json.j2를 렌더링해 Docker daemon 설정 파일로 배포한다.
    src: daemon.json.j2
    dest: /etc/docker/daemon.json
    owner: root
    group: root
    mode: "0644"
```

```jinja
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

다만 Ansible은 대상 서버 접속 권한과 네트워크 연결이 필요하고, 잘못 작성한 플레이북은 여러 서버에 동시에 영향을 줄 수 있다. 모든 작업이 자동으로 멱등성을 보장하는 것도 아니므로 모듈 선택, 조건 처리, 단계적 반영 절차를 함께 설계해야 한다.
