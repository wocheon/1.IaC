# Docker WEB-WAS Ansible examples

- `v1/`: `Blueprint.md`를 그대로 구현한 task/include 기반 구성
- `v2/`: 루트 `main.yaml`이 Docker, FastAPI, Nginx Role을 호출하는 구성

V1 실행:

```bash
ansible-playbook -i v1/inventory.ini v1/main.yaml
```

V2 실행:

```bash
cd v2
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook main.yaml
```

두 버전 모두 실행 전에 예제 인벤토리의 IP와 SSH 접속 정보를 실제 환경에
맞게 수정해야 한다.
