# Goal: Ansible 기술 블로그 문서 작성


## Objective

현재 프로젝트의 `ansible/` 디렉토리 내용을 기반으로 기술 블로그용 포스트 문서를 작성한다.

최종 주제는 **“Ansible을 활용한 여러 서버 관리 방법”** 이다.

## Context

* 작업 대상은 현재 열린 프로젝트다.
* `ansible/` 디렉토리에는 여러 서버를 관리하기 위한 Ansible 관련 구성이 들어 있다.
* `참고용_문서.docx`는 문서 양식, 제목 구조, 문체, 섹션 구성, 표/코드 블록 스타일을 참고하기 위한 파일이다.
* `참고용_문서.docx`의 문장을 그대로 복사하지 않고, 구조와 톤만 참고한다.

## Scope

### Do

* `ansible/` 디렉토리 전체 구조를 분석한다.
* Inventory, Playbook, Role, Task, Variable, Template, Handler 구성이 있는지 확인한다.
* `참고용_문서.docx`의 문서 구조와 스타일을 확인한다.
* 기술 블로그용 Markdown 문서를 작성한다.
* 실제 `ansible/` 디렉토리 구성과 연결되는 설명을 포함한다.
* Ansible 기본 개념과 기본 사용법을 함께 설명한다.

### Do not

* `ansible/` 디렉토리의 실제 파일은 수정하지 않는다.
* 서버에 접속하지 않는다.
* `ansible`, `ansible-playbook`, `ssh`, `scp`, `rsync`, `kubectl` 등 원격 실행 또는 운영 변경 가능성이 있는 명령은 실행하지 않는다.
* `참고용_문서.docx`의 내용을 그대로 복사하지 않는다.
* 프로젝트에서 확인되지 않은 내용을 사실처럼 작성하지 않는다.
* IP, 계정명, password, token, private key, secret 값은 문서에 그대로 노출하지 않는다.

## Document Requirements

산출물 경로:

```text
docs/ansible-blog-post.md
```

문서에는 다음 내용을 포함한다.

* Ansible을 사용하는 이유
* 여러 서버를 수동 관리할 때 발생하는 문제
* Ansible 기반 서버 관리 방식
* Inventory 개념과 예시
* Playbook 개념과 예시
* Module 개념과 기본 모듈 예시
* Task 개념
* Role 개념
* Variable 개념
* Template 개념
* Handler 개념
* 멱등성(Idempotency) 개념
* `ansible` 명령 기본 사용법
* `ansible-playbook` 기본 사용법
* 프로젝트 `ansible/` 디렉토리 구조 설명
* 여러 서버에 동일 설정을 적용하는 예시
* 운영 환경에서 사용할 때의 주의사항
* Ansible 방식의 장점과 한계
* 마무리 요약

## Writing Rules

* 한국어로 작성한다.
* 핵심 기술 용어는 영어 원문을 함께 병기한다.

  * 예: 멱등성(Idempotency), 인벤토리(Inventory), 플레이북(Playbook)
* 기술 블로그 독자가 이해하기 쉬운 흐름으로 작성한다.
* 설명 순서는 가능하면 다음 구조를 따른다.

  1. 개념 설명
  2. 구체적 예시 또는 코드
  3. 장단점 또는 운영 시 주의사항
* 코드 블록은 Markdown fence를 사용한다.
* YAML 예시는 문법적으로 유효해야 한다.
* 실제 서버 정보는 placeholder로 작성한다.

  * `<SERVER_IP>`
  * `<USERNAME>`
  * `<PRIVATE_KEY_PATH>`
  * `<SECRET_VALUE>`

## Verification

작성 후 다음을 점검한다.

* `docs/ansible-blog-post.md` 파일이 생성되었는지
* Markdown heading 구조가 자연스러운지
* 코드 블록이 정상적으로 닫혔는지
* YAML 예시가 문법적으로 깨지지 않았는지
* `ansible/` 디렉토리 실제 구성과 문서 설명이 충돌하지 않는지
* 민감 정보가 문서에 노출되지 않았는지

`markdownlint`가 설치되어 있으면 다음을 실행한다.

```bash
markdownlint docs/ansible-blog-post.md
```

`markdownlint`가 없으면 설치하지 말고 수동 검토 결과를 요약한다.

## Final Response

작업 완료 후 다음 내용을 요약한다.

* 생성한 문서 경로
* 문서의 주요 섹션 요약
* `ansible/` 디렉토리에서 참고한 주요 구성
* 실행한 검증 또는 수동 검토 결과
* 사람이 추가로 확인해야 할 부분
