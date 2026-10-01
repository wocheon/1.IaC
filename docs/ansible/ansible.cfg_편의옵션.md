
# Ansible.cfg - 편의를 위한 옵션

- Ansible의 기본 설정파일인 /etc/ansible/ansible.cfg에서  다음과 같이 설정가능


```ini
[defaults]
inventory = /etc/ansible/hosts

# 병렬 실행 수 (기본 5)
forks = 20

# Python interpreter 자동 탐색 경고 제거
interpreter_python = auto_silent

# 결과를 보기 편하게 출력 (2.13+)
callback_result_format = yaml

# 실패 시 task 파일/라인 표시
show_task_path_on_failure = True

[ssh_connection]
# SSH 왕복 횟수 감소
pipelining = True
```
