# 5. 실제 적용 예시: Docker 설치와 Nginx-FastAPI 구성

다음은 `task_example` 디렉터리의 구성을 바탕으로 한 실제 적용 예시다. 목적은 여러 서버에 Docker Engine을 설치하고 Docker와 containerd의 root 경로를 별도 데이터 디렉터리로 변경한 뒤, WEB 서버에는 Nginx를 실행하고 APP 서버에서는 FastAPI 애플리케이션 이미지를 직접 Build하여 실행하는 것이다.

Nginx는 외부 요청을 받아 FastAPI 서버로 전달하는 Reverse Proxy 역할을 수행한다.

```text
Client
  │
  │ HTTP :80
  ▼
web01
Nginx Container
  │
  │ HTTP :8000
  ▼
app01
FastAPI Container
```

APP 서버에서는 사전에 만들어진 이미지를 단순히 Pull하는 것이 아니라 Ansible이 애플리케이션 코드와 Dockerfile을 배포한 뒤 직접 이미지를 Build한다.

```text
Ansible
   │
   ├─ main.py
   ├─ requirements.txt
   └─ Dockerfile
          ↓
       app01
          ↓
     docker build
          ↓
   fastapi-demo:1.0
          ↓
      docker run
```

이 예제를 통해 `group_vars`, `include_tasks`, `when`, `template`, `handler`, Docker Build 및 서버 간 연동을 함께 확인할 수 있다.

## 5.1 디렉터리 구조

```text
task_example/
├── main.yaml
├── var_list.yaml
├── inventory.ini
├── group_vars/
│   ├── web.yaml
│   └── app.yaml
├── tasks/
│   ├── install_docker_debian.yaml
│   ├── install_docker_redhat.yaml
│   ├── configure_docker_root.yaml
│   ├── configure_containerd_root.yaml
│   ├── configure_application.yaml
│   └── verify_docker.yaml
└── templates/
    ├── docker-run.sh.j2
    ├── nginx.conf.j2
    ├── Dockerfile.j2
    ├── requirements.txt.j2
    └── main.py.j2
```

각 파일은 다음과 같은 역할을 담당한다.

```text
main.yaml
 └─ 전체 실행 순서 및 Handler 관리

var_list.yaml
 └─ Docker/containerd 공통 설정

group_vars/
 ├─ web.yaml : Nginx 설정
 └─ app.yaml : FastAPI Build 및 실행 설정

tasks/
 ├─ Docker 설치
 ├─ Docker/containerd 설정
 ├─ 애플리케이션 배포
 └─ 최종 검증

templates/
 ├─ Nginx 설정
 ├─ FastAPI 소스
 ├─ FastAPI Dockerfile
 └─ docker run 스크립트
```

---

## 5.2 inventory.ini

WEB 서버와 APP 서버를 각각 Inventory Group으로 구분한다.

```ini
[web]
web01 ansible_host=10.0.0.11

[app]
app01 ansible_host=10.0.0.12

[docker_targets:children]
web
app
```

`docker_targets`의 하위 그룹으로 `web`과 `app`을 지정했으므로 Docker 설치와 공통 설정은 모든 서버에 적용할 수 있다.

---

## 5.3 var_list.yaml

모든 서버에서 공통으로 사용하는 Docker 및 containerd 설정을 정의한다.

```yaml
---
docker_version: "28.5.1"
docker_install_latest_when_version_unavailable: true

docker_data_root: "/data/docker"

containerd_root: "/data/containerd"
containerd_state: "/run/containerd"

docker_repo_channel: "stable"

docker_log_max_size: "100m"
docker_log_max_file: "3"

docker_restart_policy: "unless-stopped"
```

서버 역할에 따라 달라지는 값은 `group_vars`에서 별도로 정의한다.

---

## 5.4 group_vars/web.yaml

WEB 서버에서는 공식 Nginx 이미지를 사용한다.

```yaml
---
application_role: "web"

docker_image: "nginx:1.27"
docker_container_name: "web-nginx"

docker_ports:
  - "80:80"

docker_volumes:
  - "/data/nginx/conf.d:/etc/nginx/conf.d:ro"

app_backend_host: "{{ hostvars[groups['app'][0]].ansible_host }}"
app_backend_port: 8000
```

`app_backend_host`는 Inventory의 `app` 그룹에서 APP 서버의 IP를 가져온다.

현재 구성에서는 다음 값으로 해석된다.

```text
app_backend_host = 10.0.0.12
app_backend_port = 8000
```

따라서 Nginx는 요청을 다음 주소로 전달한다.

```text
http://10.0.0.12:8000
```

---

## 5.5 group_vars/app.yaml

APP 서버에서는 FastAPI 애플리케이션 이미지를 직접 Build한다.

```yaml
---
application_role: "app"

docker_image: "fastapi-demo:1.0"
docker_container_name: "app-fastapi"

docker_ports:
  - "8000:8000"

docker_volumes: []

app_build_dir: "/opt/fastapi-app"

fastapi_python_image: "python:3.13-slim"
fastapi_port: 8000
fastapi_title: "Ansible FastAPI Example"
fastapi_message: "Nginx-FastAPI connection is working"
```

WEB과 달리 `docker_image`는 외부 Registry에서 Pull할 이미지가 아니라 APP 서버에서 생성할 로컬 이미지 이름이다.

```text
fastapi-demo:1.0
```

---

## 5.6 main.yaml

`main.yaml`은 전체 실행 순서와 Handler를 관리한다.

```yaml
---
- name: Install Docker Engine and deploy Nginx-FastAPI
  hosts: docker_targets
  become: true
  gather_facts: true

  vars_files:
    - var_list.yaml

  pre_tasks:
    - name: validate supported OS family
      ansible.builtin.assert:
        that:
          - ansible_os_family in ["Debian", "RedHat"]
        fail_msg: "Unsupported OS family: {{ ansible_os_family }}"
        success_msg: "Supported OS family detected: {{ ansible_os_family }}"

    - name: validate Docker and containerd paths
      ansible.builtin.assert:
        that:
          - docker_data_root is match('^/')
          - containerd_root is match('^/')
          - containerd_state is match('^/')
        fail_msg: "Docker/containerd paths must be absolute paths."

    - name: validate application variables
      ansible.builtin.assert:
        that:
          - application_role in ["web", "app"]
          - docker_image | length > 0
          - docker_container_name | length > 0
        fail_msg: "Application variables are not configured correctly."

  tasks:
    - name: include Debian-family Docker installation tasks
      ansible.builtin.include_tasks: tasks/install_docker_debian.yaml
      when: ansible_os_family == "Debian"

    - name: include RedHat-family Docker installation tasks
      ansible.builtin.include_tasks: tasks/install_docker_redhat.yaml
      when: ansible_os_family == "RedHat"

    - name: include Docker root configuration tasks
      ansible.builtin.include_tasks: tasks/configure_docker_root.yaml

    - name: include containerd root configuration tasks
      ansible.builtin.include_tasks: tasks/configure_containerd_root.yaml

    - name: apply Docker and containerd configuration changes
      ansible.builtin.meta: flush_handlers

    - name: ensure containerd service is running
      ansible.builtin.systemd:
        name: containerd
        state: started
        enabled: true

    - name: ensure Docker service is running
      ansible.builtin.systemd:
        name: docker
        state: started
        enabled: true

    - name: include application configuration tasks
      ansible.builtin.include_tasks: tasks/configure_application.yaml

    - name: apply application deployment handlers
      ansible.builtin.meta: flush_handlers

    - name: include Docker verification tasks
      ansible.builtin.include_tasks: tasks/verify_docker.yaml

  handlers:
    - name: restart containerd
      ansible.builtin.systemd:
        name: containerd
        state: restarted
        enabled: true

    - name: restart Docker
      ansible.builtin.systemd:
        name: docker
        state: restarted
        enabled: true

    - name: build FastAPI Docker image
      ansible.builtin.command:
        cmd: "docker build -t {{ docker_image }} {{ app_build_dir }}"
      when: application_role == "app"
      notify: run APP container

    - name: pull Nginx Docker image
      ansible.builtin.command:
        cmd: "docker pull {{ docker_image }}"
      listen: deploy WEB container
      when: application_role == "web"

    - name: run APP container
      ansible.builtin.command:
        cmd: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"

    - name: run WEB container
      ansible.builtin.command:
        cmd: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"
      listen: deploy WEB container
      when: application_role == "web"
```

WEB과 APP의 이미지 준비 방식이 서로 다르다는 점이 핵심이다.

```text
WEB
 Template 변경
      ↓
 docker pull nginx
      ↓
 docker run

APP
 Source/Dockerfile 변경
      ↓
 docker build
      ↓
 docker run
```

---

## 5.7 tasks/install_docker_debian.yaml

Debian 계열에서는 Docker 공식 Repository를 구성한 뒤 Docker Engine을 설치한다.

```yaml
---
- name: remove conflicting Docker packages
  ansible.builtin.apt:
    name:
      - docker.io
      - docker-compose
      - docker-compose-v2
      - docker-doc
      - podman-docker
      - containerd
      - runc
    state: absent

- name: install Docker repository prerequisites
  ansible.builtin.apt:
    name:
      - ca-certificates
      - curl
    state: present
    update_cache: true

- name: create APT keyring directory
  ansible.builtin.file:
    path: /etc/apt/keyrings
    state: directory
    owner: root
    group: root
    mode: "0755"

- name: install Docker repository GPG key
  ansible.builtin.get_url:
    url: "https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg"
    dest: /etc/apt/keyrings/docker.asc
    owner: root
    group: root
    mode: "0644"

- name: get package architecture
  ansible.builtin.command: dpkg --print-architecture
  register: docker_apt_arch
  changed_when: false

- name: configure Docker APT repository
  ansible.builtin.apt_repository:
    repo: "deb [arch={{ docker_apt_arch.stdout }} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} {{ docker_repo_channel }}"
    filename: docker
    state: present
    update_cache: true

- name: find requested Docker version
  ansible.builtin.shell: "apt-cache madison docker-ce | awk '{print $3}' | grep -F '{{ docker_version }}' | head -n 1"
  register: docker_apt_requested_version
  changed_when: false
  failed_when: false

- name: fail when requested Docker version is unavailable
  ansible.builtin.fail:
    msg: "Docker version {{ docker_version }} is not available."
  when:
    - docker_apt_requested_version.stdout | length == 0
    - not docker_install_latest_when_version_unavailable | bool

- name: install requested Docker version
  ansible.builtin.apt:
    name:
      - "docker-ce={{ docker_apt_requested_version.stdout }}"
      - "docker-ce-cli={{ docker_apt_requested_version.stdout }}"
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
  when: docker_apt_requested_version.stdout | length > 0

- name: install latest Docker when requested version is unavailable
  ansible.builtin.apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
  when:
    - docker_apt_requested_version.stdout | length == 0
    - docker_install_latest_when_version_unavailable | bool
```

---

## 5.8 tasks/install_docker_redhat.yaml

RedHat 계열에서는 `dnf`와 `yum_repository`를 사용한다.

```yaml
---
- name: remove conflicting Docker packages
  ansible.builtin.dnf:
    name:
      - docker
      - docker-client
      - docker-client-latest
      - docker-common
      - docker-latest
      - docker-latest-logrotate
      - docker-logrotate
      - docker-engine
      - podman
      - runc
    state: absent

- name: install DNF repository management package
  ansible.builtin.dnf:
    name: dnf-plugins-core
    state: present

- name: determine Docker RPM repository distribution
  ansible.builtin.set_fact:
    docker_rpm_repo_os: "{{ 'rhel' if ansible_distribution == 'RedHat' else 'centos' }}"

- name: configure Docker repository
  ansible.builtin.yum_repository:
    name: docker-ce-stable
    description: Docker CE Stable - $basearch
    baseurl: "https://download.docker.com/linux/{{ docker_rpm_repo_os }}/$releasever/$basearch/{{ docker_repo_channel }}"
    enabled: true
    gpgcheck: true
    gpgkey: "https://download.docker.com/linux/{{ docker_rpm_repo_os }}/gpg"

- name: refresh DNF repository metadata
  ansible.builtin.dnf:
    update_cache: true

- name: find requested Docker version
  ansible.builtin.shell: "dnf list docker-ce --showduplicates --quiet | awk '$1 ~ /^docker-ce\\./ {print $2}' | grep -F '{{ docker_version }}' | head -n 1"
  register: docker_rpm_requested_version
  changed_when: false
  failed_when: false

- name: fail when requested Docker version is unavailable
  ansible.builtin.fail:
    msg: "Docker version {{ docker_version }} is not available."
  when:
    - docker_rpm_requested_version.stdout | length == 0
    - not docker_install_latest_when_version_unavailable | bool

- name: install requested Docker version
  ansible.builtin.dnf:
    name:
      - "docker-ce-{{ docker_rpm_requested_version.stdout }}"
      - "docker-ce-cli-{{ docker_rpm_requested_version.stdout }}"
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
  when: docker_rpm_requested_version.stdout | length > 0

- name: install latest Docker when requested version is unavailable
  ansible.builtin.dnf:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
  when:
    - docker_rpm_requested_version.stdout | length == 0
    - docker_install_latest_when_version_unavailable | bool
```

---

## 5.9 tasks/configure_docker_root.yaml

Docker의 데이터 저장 경로를 변경한다.

```yaml
---
- name: create Docker configuration directory
  ansible.builtin.file:
    path: /etc/docker
    state: directory
    owner: root
    group: root
    mode: "0755"

- name: create Docker data-root directory
  ansible.builtin.file:
    path: "{{ docker_data_root }}"
    state: directory
    owner: root
    group: root
    mode: "0711"

- name: configure Docker daemon data-root
  ansible.builtin.copy:
    dest: /etc/docker/daemon.json
    owner: root
    group: root
    mode: "0644"
    content: |
      {
        "data-root": "{{ docker_data_root }}",
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "{{ docker_log_max_size }}",
          "max-file": "{{ docker_log_max_file }}"
        }
      }
  notify: restart Docker
```

---

## 5.10 tasks/configure_containerd_root.yaml

containerd 데이터 경로도 별도로 변경한다.

```yaml
---
- name: create containerd configuration directory
  ansible.builtin.file:
    path: /etc/containerd
    state: directory
    owner: root
    group: root
    mode: "0755"

- name: create containerd root directory
  ansible.builtin.file:
    path: "{{ containerd_root }}"
    state: directory
    owner: root
    group: root
    mode: "0711"

- name: check containerd configuration file
  ansible.builtin.stat:
    path: /etc/containerd/config.toml
  register: containerd_config

- name: generate default containerd configuration
  ansible.builtin.command: containerd config default
  register: containerd_default_config
  changed_when: false
  when: not containerd_config.stat.exists

- name: create default containerd configuration file
  ansible.builtin.copy:
    dest: /etc/containerd/config.toml
    content: "{{ containerd_default_config.stdout }}\n"
    owner: root
    group: root
    mode: "0644"
  when: not containerd_config.stat.exists
  notify:
    - restart containerd
    - restart Docker

- name: configure containerd root directory
  ansible.builtin.lineinfile:
    path: /etc/containerd/config.toml
    regexp: '^root\s*='
    line: 'root = "{{ containerd_root }}"'
    insertbefore: '^\['
  notify:
    - restart containerd
    - restart Docker

- name: configure containerd state directory
  ansible.builtin.lineinfile:
    path: /etc/containerd/config.toml
    regexp: '^state\s*='
    line: 'state = "{{ containerd_state }}"'
    insertbefore: '^\['
  notify:
    - restart containerd
    - restart Docker
```

---

## 5.11 templates/nginx.conf.j2

WEB 서버의 Nginx가 APP 서버의 FastAPI로 요청을 전달하도록 설정한다.

```nginx
server {
    listen 80;
    server_name _;

    location = /health {
        add_header Content-Type text/plain;
        return 200 "nginx ok\n";
    }

    location / {
        proxy_pass http://{{ app_backend_host }}:{{ app_backend_port }};

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

`web01`에서는 다음과 같이 렌더링된다.

```nginx
proxy_pass http://10.0.0.12:8000;
```

---

## 5.12 templates/main.py.j2

APP 서버에서 Build할 FastAPI 애플리케이션 소스를 Template으로 생성한다.

```python
from fastapi import FastAPI

app = FastAPI(title="{{ fastapi_title }}")

@app.get("/")
def root():
    return {
        "message": "{{ fastapi_message }}",
        "backend": "FastAPI"
    }

@app.get("/health")
def health():
    return {
        "status": "ok"
    }
```

`group_vars/app.yaml`의 변수가 적용되므로 실제 응답은 다음과 같다.

```json
{
  "message": "Nginx-FastAPI connection is working",
  "backend": "FastAPI"
}
```

---

## 5.13 templates/requirements.txt.j2

FastAPI 실행에 필요한 Python 패키지를 정의한다.

```text
fastapi[standard]
```

이 예제에서는 구성을 단순하게 보여주기 위해 패키지 버전을 고정하지 않는다. 실제 운영 이미지에서는 검증된 패키지 버전을 고정하여 동일한 이미지를 재현할 수 있도록 관리하는 것이 적절하다.

---

## 5.14 templates/Dockerfile.j2

APP 서버에서 FastAPI 이미지를 생성할 Dockerfile이다.

```dockerfile
FROM {{ fastapi_python_image }}

WORKDIR /code

COPY requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir -r /code/requirements.txt

COPY app /code/app

EXPOSE {{ fastapi_port }}

CMD ["fastapi", "run", "app/main.py", "--port", "{{ fastapi_port }}", "--proxy-headers"]
```

Dockerfile에서는 변경 빈도가 낮은 Dependency 파일을 먼저 복사하고 설치한 뒤 애플리케이션 소스를 복사한다.

따라서 애플리케이션 코드만 변경된 경우 기존 Dependency Layer를 Docker Build Cache에서 재사용할 수 있다.

APP 서버에는 최종적으로 다음 Build Context가 생성된다.

```text
/opt/fastapi-app/
├── Dockerfile
├── requirements.txt
└── app/
    └── main.py
```

이미지는 다음 명령으로 생성된다.

```bash
docker build -t fastapi-demo:1.0 /opt/fastapi-app
```

---

## 5.15 templates/docker-run.sh.j2

WEB과 APP 모두 동일한 Template을 사용하여 컨테이너 실행 스크립트를 생성한다.

```bash
#!/usr/bin/env bash
set -euo pipefail

docker rm -f "{{ docker_container_name }}" >/dev/null 2>&1 || true

docker run -d \
  --name "{{ docker_container_name }}" \
  --restart "{{ docker_restart_policy }}" \
{% for port in docker_ports | default([]) %}
  -p "{{ port }}" \
{% endfor %}
{% for volume in docker_volumes | default([]) %}
  -v "{{ volume }}" \
{% endfor %}
  "{{ docker_image }}"
```

WEB 서버에서는 다음과 같은 형태가 된다.

```bash
docker run -d \
  --name "web-nginx" \
  --restart "unless-stopped" \
  -p "80:80" \
  -v "/data/nginx/conf.d:/etc/nginx/conf.d:ro" \
  "nginx:1.27"
```

APP 서버에서는 다음과 같다.

```bash
docker run -d \
  --name "app-fastapi" \
  --restart "unless-stopped" \
  -p "8000:8000" \
  "fastapi-demo:1.0"
```

---

## 5.16 tasks/configure_application.yaml

WEB 서버에서는 Nginx 설정을 생성하고, APP 서버에서는 FastAPI Build Context를 생성한다.

```yaml
---
- name: create Nginx configuration directory
  ansible.builtin.file:
    path: /data/nginx/conf.d
    state: directory
    owner: root
    group: root
    mode: "0755"
  when: application_role == "web"

- name: deploy Nginx reverse proxy configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /data/nginx/conf.d/default.conf
    owner: root
    group: root
    mode: "0644"
  when: application_role == "web"
  notify: deploy WEB container

- name: create FastAPI build directory
  ansible.builtin.file:
    path: "{{ app_build_dir }}/app"
    state: directory
    owner: root
    group: root
    mode: "0755"
  when: application_role == "app"

- name: deploy FastAPI application source
  ansible.builtin.template:
    src: main.py.j2
    dest: "{{ app_build_dir }}/app/main.py"
    owner: root
    group: root
    mode: "0644"
  when: application_role == "app"
  notify: build FastAPI Docker image

- name: deploy FastAPI requirements
  ansible.builtin.template:
    src: requirements.txt.j2
    dest: "{{ app_build_dir }}/requirements.txt"
    owner: root
    group: root
    mode: "0644"
  when: application_role == "app"
  notify: build FastAPI Docker image

- name: deploy FastAPI Dockerfile
  ansible.builtin.template:
    src: Dockerfile.j2
    dest: "{{ app_build_dir }}/Dockerfile"
    owner: root
    group: root
    mode: "0644"
  when: application_role == "app"
  notify: build FastAPI Docker image

- name: deploy WEB Docker run script
  ansible.builtin.template:
    src: docker-run.sh.j2
    dest: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"
    owner: root
    group: root
    mode: "0755"
  when: application_role == "web"
  notify: deploy WEB container

- name: deploy APP Docker run script
  ansible.builtin.template:
    src: docker-run.sh.j2
    dest: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"
    owner: root
    group: root
    mode: "0755"
  when: application_role == "app"
  notify: build FastAPI Docker image

- name: check application container
  ansible.builtin.command:
    cmd: "docker container inspect {{ docker_container_name }}"
  register: application_container_check
  changed_when: false
  failed_when: false

- name: trigger WEB deployment when container does not exist
  ansible.builtin.command: /bin/true
  changed_when: true
  when:
    - application_role == "web"
    - application_container_check.rc != 0
  notify: deploy WEB container

- name: trigger APP deployment when container does not exist
  ansible.builtin.command: /bin/true
  changed_when: true
  when:
    - application_role == "app"
    - application_container_check.rc != 0
  notify: build FastAPI Docker image
```

APP 서버에서 다음 파일 중 하나라도 변경되면 이미지 Build가 다시 수행된다.

```text
Dockerfile
requirements.txt
app/main.py
docker-run-app-fastapi.sh
```

실행 흐름은 다음과 같다.

```text
main.py.j2
requirements.txt.j2
Dockerfile.j2
       │
       │ changed
       ▼
notify
       │
       ▼
build FastAPI Docker image
       │
       ▼
docker build
       │
       ▼
fastapi-demo:1.0
       │
       ▼
notify
       │
       ▼
run APP container
       │
       ▼
docker run
```

WEB 서버는 별도의 Build 과정 없이 Nginx 이미지를 Pull하여 실행한다.

```text
nginx.conf.j2
      │
      ▼
notify
      │
      ▼
docker pull nginx
      │
      ▼
docker run
```

---

## 5.17 Handler 동작

APP 서버에서 FastAPI 관련 Template이 변경되면 `build FastAPI Docker image` Handler가 실행된다.

```yaml
- name: build FastAPI Docker image
  ansible.builtin.command:
    cmd: "docker build -t {{ docker_image }} {{ app_build_dir }}"
  when: application_role == "app"
  notify: run APP container
```

이미지 Build가 완료되면 다시 `run APP container` Handler가 호출된다.

```yaml
- name: run APP container
  ansible.builtin.command:
    cmd: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"
```

WEB 서버에서는 `deploy WEB container` 이벤트를 통해 Nginx Image Pull과 실행 Handler를 호출한다.

```yaml
- name: pull Nginx Docker image
  ansible.builtin.command:
    cmd: "docker pull {{ docker_image }}"
  listen: deploy WEB container
  when: application_role == "web"

- name: run WEB container
  ansible.builtin.command:
    cmd: "/usr/local/bin/docker-run-{{ docker_container_name }}.sh"
  listen: deploy WEB container
  when: application_role == "web"
```

따라서 서버 역할에 따라 서로 다른 배포 방식이 적용된다.

```text
WEB                          APP

nginx.conf                   Python Source
    ↓                             ↓
Template                       Template
    ↓                             ↓
notify                         notify
    ↓                             ↓
docker pull                   docker build
    ↓                             ↓
docker run                    docker run
```

---

## 5.18 tasks/verify_docker.yaml

마지막으로 Docker/containerd 설정과 애플리케이션 상태를 검증한다.

```yaml
---
- name: check Docker information
  ansible.builtin.command: docker info
  register: docker_info_check
  changed_when: false

- name: check containerd configuration
  ansible.builtin.shell: "grep -E '^(root|state)\\s*=' /etc/containerd/config.toml"
  register: containerd_config_check
  changed_when: false

- name: check Docker service status
  ansible.builtin.command: systemctl is-active docker
  register: docker_service_status
  changed_when: false
  failed_when: false

- name: check containerd service status
  ansible.builtin.command: systemctl is-active containerd
  register: containerd_service_status
  changed_when: false
  failed_when: false

- name: check application image
  ansible.builtin.command:
    cmd: "docker image inspect {{ docker_image }}"
  register: docker_image_check
  changed_when: false
  failed_when: false

- name: check running application container
  ansible.builtin.command:
    cmd: "docker ps --filter name={{ docker_container_name }} --filter status=running -q"
  register: application_container_running
  changed_when: false

- name: verify FastAPI health endpoint
  ansible.builtin.uri:
    url: "http://127.0.0.1:8000/health"
    return_content: true
    status_code: 200
  register: app_response
  when: application_role == "app"

- name: verify WEB to FastAPI connection
  ansible.builtin.uri:
    url: "http://127.0.0.1/"
    return_content: true
    status_code: 200
  register: web_response
  when: application_role == "web"

- name: validate common Docker configuration
  ansible.builtin.assert:
    that:
      - docker_service_status.stdout == "active"
      - containerd_service_status.stdout == "active"
      - docker_image_check.rc == 0
      - application_container_running.stdout | length > 0
      - "'Docker Root Dir: ' + docker_data_root in docker_info_check.stdout"
      - "'root = \"' + containerd_root + '\"' in containerd_config_check.stdout"
      - "'state = \"' + containerd_state + '\"' in containerd_config_check.stdout"
    fail_msg: "Docker configuration verification failed."

- name: validate FastAPI response
  ansible.builtin.assert:
    that:
      - app_response.json.status == "ok"
    fail_msg: "FastAPI health check failed."
    success_msg: "FastAPI application is running normally."
  when: application_role == "app"

- name: validate Nginx-FastAPI connection
  ansible.builtin.assert:
    that:
      - "'Nginx-FastAPI connection is working' in web_response.content"
    fail_msg: "Nginx-FastAPI connection verification failed."
    success_msg: "Nginx-FastAPI connection is working normally."
  when: application_role == "web"

- name: show deployment result
  ansible.builtin.debug:
    msg:
      - "Role: {{ application_role }}"
      - "Docker image: {{ docker_image }}"
      - "Container: {{ docker_container_name }}"
      - "Docker Root Dir: {{ docker_data_root }}"
      - "Docker service: {{ docker_service_status.stdout }}"
      - "containerd service: {{ containerd_service_status.stdout }}"
```

APP 서버에서는 FastAPI 자체 상태를 확인한다.

```text
http://127.0.0.1:8000/health
```

WEB 서버에서는 Nginx를 통해 FastAPI 응답을 확인한다.

```text
http://127.0.0.1/
       │
       ▼
     Nginx
       │
       ▼
10.0.0.12:8000
       │
       ▼
    FastAPI
```

따라서 WEB 검증까지 성공했다면 다음 전체 경로가 정상적으로 동작한다는 의미다.

```text
Client
  ↓
Nginx Container
  ↓
Network
  ↓
FastAPI Container
```

---

## 5.19 실행 방법

전체 서버에 적용한다.

```bash
ansible-playbook -i inventory.ini main.yaml
```

특정 역할만 실행할 수도 있다.

```bash
ansible-playbook -i inventory.ini main.yaml --limit app
ansible-playbook -i inventory.ini main.yaml --limit web
```

첫 실행 시 APP 서버에서는 다음 과정이 수행된다.

```text
FastAPI 소스 배포
      ↓
Dockerfile 생성
      ↓
docker build
      ↓
fastapi-demo:1.0
      ↓
docker run
```

이후 `main.py.j2`의 다음 값을 변경하면,

```yaml
fastapi_message: "FastAPI application updated"
```

Ansible은 `main.py` 변경을 감지하여 FastAPI 이미지를 다시 Build하고 컨테이너를 재생성한다.

---

## 5.20 이 예시에서 사용한 주요 운영 패턴

첫째, Inventory Group으로 서버 역할을 분리한다.

```text
web
 └─ web01

app
 └─ app01
```

둘째, 공통 설정은 `var_list.yaml`, 역할별 설정은 `group_vars`에서 관리한다.

```text
var_list.yaml
 └─ Docker/containerd 공통값

group_vars/web.yaml
 └─ Nginx 설정

group_vars/app.yaml
 └─ FastAPI Build 및 실행 설정
```

셋째, OS별 Docker 설치 과정은 `when`과 `include_tasks`를 사용해 분리한다.

넷째, `template`을 이용하여 Nginx 설정뿐 아니라 애플리케이션 코드와 Dockerfile까지 동적으로 생성한다.

```text
WEB                         APP

nginx.conf.j2               main.py.j2
                            Dockerfile.j2
                            requirements.txt.j2
       │                         │
       ▼                         ▼
     Nginx                    FastAPI
```

다섯째, Handler를 사용하여 파일이 실제로 변경된 경우에만 이미지 Pull 또는 Build와 컨테이너 재배포를 수행한다.

```text
WEB                          APP

Template 변경                Source 변경
     ↓                           ↓
 Handler                       Handler
     ↓                           ↓
docker pull                  docker build
     ↓                           ↓
docker run                   docker run
```

마지막으로 `uri` 모듈로 APP 자체 Health Check와 WEB을 통한 End-to-End 통신을 각각 검증한다.

---

## 5.21 적용 시 주의사항

WEB 서버에서 APP 서버의 `8000/tcp`로 접근할 수 있어야 한다.

```text
Client
  │
  │ TCP 80
  ▼
WEB
  │
  │ TCP 8000
  ▼
APP
```

외부 사용자가 APP 서버의 8000 Port에 직접 접근할 필요는 없으므로 실제 환경에서는 WEB 서버에서 APP 서버로의 통신만 허용하는 것이 적절하다.

또한 이 예제는 Ansible의 `template`과 `handler`, Docker Build 과정을 함께 보여주기 위해 **APP 서버 자체에서 이미지를 Build**한다.

소규모 환경이나 교육/개발 환경에서는 충분히 사용할 수 있지만, 서비스 규모가 커지고 동일 이미지를 여러 서버에 배포해야 한다면 다음 구조가 더 적합하다.

```text
Source
  ↓
CI/CD
  ↓
Docker Build
  ↓
Container Registry
  ↓
APP Servers
  ↓
docker pull
```

즉 운영 규모가 커지면 각 APP 서버에서 동일한 이미지를 반복 Build하기보다 CI/CD에서 한 번 Build한 이미지를 Registry에 저장하고 동일한 Image Tag 또는 Digest를 각 서버에서 Pull하는 방식이 재현성과 배포 일관성 측면에서 유리하다.

현재 예제에서는 Docker 설치와 Ansible 기능을 실제 애플리케이션 배포 흐름으로 연결하는 것이 목적이므로 **Nginx는 Pull, FastAPI는 대상 APP 서버에서 Build하여 실행하는 정도가 적절한 구성이다.**
