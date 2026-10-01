# Docker WEB-WAS Ansible 예제 V2

V2는 현재 디렉터리의 `main.yaml`을 실행 진입점으로 사용하고, 실제 작업은
다음 세 Role에 분리한다.

```text
docker_engine -> fastapi_app -> nginx_proxy
```

각 Play에는 `any_errors_fatal: true`가 설정되어 있다. 대상 호스트 중 하나라도
실패하면 전체 Playbook을 중단하므로, APP 애플리케이션의 상태 확인이 성공한
뒤에만 WEB 서버가 구성된다.

## 대상 서버

기본 인벤토리는 `inventories/example/hosts.ini`이다.

```text
docker_targets
├── web
│   └── web-1 (192.168.1.10)
└── app
    └── was-1 (192.168.1.20)
```

- `ansible_host`: Ansible이 SSH로 접속할 주소
- `private_ip`: Nginx가 FastAPI에 요청을 전달할 때 사용하는 내부 주소
- `docker_targets`: `web`과 `app` 그룹을 포함하는 부모 그룹

WEB 서버에서 APP 서버의 `8000/tcp`에 접근할 수 있어야 한다.

## 전체 실행 순서

`main.yaml`에는 세 개의 Play가 선언되어 있으며 위에서 아래 순서로 실행된다.

```text
1. docker_targets : Docker Engine과 containerd 설치 및 설정
          ↓
2. app            : FastAPI 이미지 Build, 컨테이너 실행 및 상태 확인
          ↓
3. web            : Nginx Reverse Proxy 실행 및 전체 연결 확인
```

### 1. 설정과 변수 로드

`v2` 디렉터리에서 실행하면 `ansible.cfg`가 다음 항목을 자동으로 적용한다.

```text
inventory  = inventories/example/hosts.ini
roles_path = roles
```

변수는 다음 구조로 적용된다.

```text
roles/*/defaults/main.yml
            ↓ 환경별 값으로 덮어쓰기
inventories/example/group_vars/all.yml
inventories/example/group_vars/app.yml
inventories/example/group_vars/web.yml
```

`all.yml`은 APP과 WEB이 함께 사용하는 포트, 응답 메시지, Docker 데이터
경로를 정의한다. `app.yml`과 `web.yml`은 각 서버 역할에만 필요한 이미지,
컨테이너 이름, 포트 등을 정의한다.

### 2. docker_engine Role 실행

첫 번째 Play는 `docker_targets`에 포함된 `web-1`과 `was-1`에서 실행된다.

```text
입력 변수와 지원 OS 검증
          ↓
OS 계열에 따른 설치 Task 선택
├── Debian/Ubuntu : tasks/debian.yml
└── RedHat 계열   : tasks/redhat.yml
          ↓
Docker Engine 및 containerd 설정
          ↓
Handler 실행
          ↓
서비스 시작 및 설정 결과 검증
```

Debian/Ubuntu 계열에서는 다음 순서로 설치한다.

1. 충돌할 수 있는 기존 Docker, containerd, Podman 패키지를 제거한다.
2. Docker 공식 저장소에 필요한 패키지, `python3-requests`, GPG 키를 설치한다.
3. 대상 배포판 코드네임과 아키텍처에 맞는 APT 저장소를 등록한다.
4. 저장소에서 제공하는 `docker-ce` 버전 목록을 조회한다.
5. `docker_engine_version`이 `latest`이면 최신 패키지를 설치한다.
6. 고정 버전이면 전체 패키지 버전 문자열을 찾아 해당 버전을 설치한다.

APT 또는 dpkg가 `unattended-upgrades` 같은 다른 프로세스에 의해 사용 중이면
프로세스를 강제 종료하지 않고 잠금이 해제될 때까지 최대 900초 기다린다.
대기 시간은 `docker_engine_apt_lock_timeout` 변수로 변경할 수 있다.

고정 버전이 존재하지 않으면 대상 OS, 코드네임, 아키텍처와 사용 가능한
버전 목록을 출력하고 실행을 중단한다. 저장소 자체에서 패키지를 찾지 못한
경우에는 저장소 설정을 확인할 수 있는 진단 메시지를 출력한다.

RedHat 계열도 같은 방식으로 동작하지만 APT 대신 DNF 저장소와 패키지를
사용한다. APP/WEB Role의 `community.docker` 모듈이 대상 서버의 Python에서
동작할 수 있도록 RedHat 계열에도 `python3-requests`를 설치한다.

패키지 설치 직후에는 Ansible이 대상 서버에서 실제로 사용하는 Python
인터프리터로 `import requests`를 실행한다. 이 검증이 성공해야 Docker 설정과
APP/WEB 컨테이너 배포 단계로 진행한다.

설치 후 `tasks/configure.yml`은 다음 작업을 수행한다.

1. Docker 데이터 경로와 `/etc/docker` 디렉터리를 생성한다.
2. `daemon.json.j2`를 렌더링하고 `dockerd --validate`로 문법을 검사한다.
3. 기존 `/etc/docker/daemon.json`을 백업한 뒤 새 설정을 반영한다.
4. containerd 설정이 없으면 `containerd config default`로 생성한다.
5. containerd의 `root`와 `state` 경로를 설정한다.
6. 설정이 변경되면 Handler에 재시작을 요청한다.

`flush_handlers` 시점에는 containerd를 먼저 재시작하고 그다음 Docker를
재시작한다. 이후 두 서비스를 활성화하고 실행한 뒤 다음 값을 검증한다.

```text
Docker Root Dir == docker_engine_data_root
containerd root == containerd_root
containerd state == containerd_state
```

이 검증이 실패하면 APP과 WEB 배포는 진행되지 않는다.

### 3. fastapi_app Role 실행

두 번째 Play는 `app` 그룹의 `was-1`에서 실행된다.

```text
FastAPI 변수 검증
        ↓
/opt/fastapi-app Build Context 생성
├── Dockerfile
├── requirements.txt
└── app/main.py
        ↓
기존 fastapi-demo 이미지 조회
        ↓
소스 변경 또는 이미지 부재 여부 판단
        ↓
필요한 경우에만 Docker 이미지 Build
        ↓
FastAPI 컨테이너 상태 수렴
        ↓
/health 응답 대기 및 검증
```

`Dockerfile`, `requirements.txt`, `main.py` 중 하나가 변경됐거나 로컬 이미지가
없는 경우에만 이미지를 다시 Build한다. 단순 재실행 시 Build Context가
변경되지 않았고 이미지가 존재하면 Build를 건너뛴다.

`community.docker.docker_container`가 `app-fastapi` 컨테이너의 이미지,
포트, 재시작 정책과 실행 상태를 선언된 값으로 맞춘다. 애플리케이션은
컨테이너 내부에서 UID `10001`의 일반 사용자로 실행된다.

컨테이너 실행 후 다음 주소를 기본 5초 간격으로 최대 12회 확인한다.

```text
http://127.0.0.1:8000/health
```

응답의 `status` 값이 `ok`가 되어야 APP Play가 성공한다. 제한 시간 안에
정상 응답을 받지 못하면 실행을 중단하므로 Nginx는 아직 배포되지 않는다.

### 4. nginx_proxy Role 실행

세 번째 Play는 `web` 그룹의 `web-1`에서 실행된다.

```text
WEB 변수와 APP 그룹 검증
        ↓
app 그룹의 모든 private_ip 조회
        ↓
Nginx upstream 설정 생성
        ↓
Nginx 컨테이너 상태 수렴
        ↓
Nginx를 통한 FastAPI 응답 검증
```

`default.conf.j2`는 `app` 그룹에 등록된 모든 호스트를 upstream 서버로
추가한다. 현재 인벤토리에서는 다음 주소가 생성된다.

```nginx
upstream fastapi_backend {
    server 192.168.1.20:8000;
}
```

APP 호스트가 여러 개라면 각 호스트의 `private_ip`가 upstream에 자동으로
추가된다. 설정을 배포한 뒤 `community.docker.docker_container`가
`web-nginx` 컨테이너를 실행한다. Nginx 설정이 변경된 경우에는 컨테이너를
재생성하여 새 설정을 반영한다.

마지막으로 WEB 서버 자신의 80번 포트에 요청을 보내 다음 전체 경로를
검증한다.

```text
Ansible uri
    ↓ http://127.0.0.1/
web-1 Nginx container
    ↓ http://192.168.1.20:8000
was-1 FastAPI container
    ↓
application_expected_message 응답 확인
```

기본 5초 간격으로 최대 12회 재시도하며, FastAPI 응답에 지정된 메시지가
포함되어야 전체 배포가 성공한다.

## 재실행 시 동작

Ansible 모듈은 현재 상태와 원하는 상태를 비교하므로 변경이 없다면 대부분의
Task는 `ok`로 끝난다.

- 패키지가 이미 원하는 상태이면 다시 설치하지 않는다.
- Docker/containerd 설정이 같으면 서비스를 재시작하지 않는다.
- FastAPI Build Context가 같고 이미지가 있으면 이미지를 다시 Build하지 않는다.
- 컨테이너 설정이 같으면 컨테이너를 불필요하게 재생성하지 않는다.
- Nginx 설정이 바뀐 경우에만 Nginx 컨테이너를 재생성한다.
- 상태 확인은 매 실행마다 수행한다.

## 요구사항

- Ansible Core 2.15 이상
- 모든 대상 서버에 대한 SSH 접속 및 권한 상승 권한
- WEB 서버에서 APP 서버의 TCP 8000 포트로 접근 가능한 네트워크

`v2` 디렉터리에서 고정된 Collection을 설치한다.

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

## 실행 방법

먼저 예제 인벤토리의 주소와 SSH 접속 정보를 실제 환경에 맞게 수정한다.
그다음 `v2` 디렉터리에서 실행한다.

```bash
cd v2
ansible-playbook main.yaml --syntax-check
ansible-playbook main.yaml
```

인벤토리를 명시적으로 지정할 수도 있다.

```bash
ansible-playbook -i inventories/example/hosts.ini main.yaml
```

이미 선행 조건이 구성된 서버에서는 Role 태그로 일부 단계만 실행할 수 있다.

```bash
ansible-playbook main.yaml --tags docker
ansible-playbook main.yaml --tags app
ansible-playbook main.yaml --tags web
```

`app` 또는 `web` 태그만 실행할 때는 Docker Engine과 필요한 이미지 등 선행
조건이 이미 준비되어 있어야 한다.

## 운영 시 주의사항

- Docker Role은 `/etc/docker/daemon.json` 전체를 관리하며 변경 전 백업한다.
- Docker 또는 containerd 데이터 경로를 바꿔도 기존 데이터를 자동으로
  이전하지 않는다. 새 서버에 적용하거나 별도의 데이터 이전 계획을 세워야 한다.
- 예제 기본값은 배포판 저장소의 최신 Docker 패키지를 설치한다. 버전을
  고정하려면 대상 저장소에서 제공되는 것을 확인한 뒤 인벤토리에
  `docker_engine_version`을 지정한다.
- FastAPI 패키지는 버전을 고정했지만 Base Image는 예제용 Tag를 사용한다.
  운영 환경에서는 검증한 Image Digest를 사용하는 것이 좋다.
- 이 예제는 APP 서버에서 이미지를 직접 Build한다. 서버가 많아지면 CI/CD에서
  한 번 Build한 이미지를 Registry에 저장하고 APP 서버에서 Pull하는 구조가
  적합하다.
