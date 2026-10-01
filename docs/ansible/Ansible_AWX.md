# Ansible AWX
## AWX
- ansible tower 의 오픈소스 버전으로,
ansible 을 GUI 로 관리하고, api 로 제어할 수 있도록 해주는 시스템.
## AWX 공식매뉴얼
[https://docs.ansible.com/ansible-tower/latest/html/userguide/](https://docs.ansible.com/ansible-tower/latest/html/userguide/)


### 최소 사양 
 - CPU 4 코어 이상, 메모리 8GB 이상

### 필요 패키지
git 
ansible
docker & docker-compose  or K8S
python3
python-pip
## AWX 설치 
- CentOS7 기준으로 설치 진행
- git repo를 clone 후 install 하는 방식으로 진행
- Ansible AWX ver 17을 기준으로 설치방법이 달라짐
    - Version 17 이하는 Linux OS 위에 Docker를 기반으로 설치를 진행
    - Version 18 이상부터는 Kubernetes 기반 위에서 설치
### selinux 및 방화벽 해제
```bash
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config ; setenforce 0; systemctl disable firewalld --now;
```
### 필수 패키지 설치
```bash
yum -y install epel-release yum-utils curl git wget
# python3 사용시
yum -y install ansible python-pip python3-pip python3 libselinux-python3 
```
### docker 설치
```bash
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
yum install -y device-mapper-persistent-data lvm2
systemctl enable docker --now
```
### docker-compose 설치
```bash
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```
### AWX 17 버전 다운로드
```bash
mkdir /work
cd /work/
git clone -b 17.1.0 https://github.com/Ansible/awx.git
```
    
### AWX 설정 변경    
```bash
cd /work/awx/installer/
```
>vi inventory
```bash
# This will create or update a default admin (superuser) account in AWX, if not provided
# then these default values are used
admin_user=admin
#해당라인 주석 해제 후 패스워드 변경
admin_password=admin 
# Local directory that is mounted in the awx_postgres docker container to place the db in
# 경로를 절대경로로 변경
postgres_data_dir="/root/.awx/pgdocker"
host_port=80
host_port_ssl=443
#ssl_certificate=
# Optional key file
#ssl_certificate_key=
docker_compose_dir="/root/.awx/awxcompose"
# 로컬 디렉토리 사용시 해당라인 주석 해제 필요
project_data_dir=/var/lib/awx/projects
```
### pip upgrade 진행 및 docker-compose 모듈 설치
```bash
# python2 사용시
#업그레이드 버전차이가 많이나면 오류 발생하므로 중간 버전 설치 후 진행
#pip install --upgrade pip==20.3
#pip install --upgrade pip
#pip uninstall docker docker-py docker-compose
pip-3 install docker docker-compose
```
### AWX 설치 진행
```bash
# 오류나면 다시 한번 돌려보기
ansible-playbook -i inventory install.yml
```
### AWX 접속 확인
- http:[awx서버 ip]
- 포트기본값 : 80 (inventory파일로 변경가능)
- admin/admin
 ---
## AWX 메뉴
- AWX의 메뉴는 다음과 같이 구성되어있음
### View
- 작업 현황 조회
    - Dashboard
        - 기본 대시보드 화면
    - Jobs
        - Job 실행 기록 ( 성공/실패 )
    - Schedules
        - 스케쥴로 걸려있는 Job 목록
    - Activity Stream
        - AWX내의 모든 활동이 기록됨
    - Workflow Approvals
        - 워크 플로우 승인 관련(추후 Templeate에서 설명)
### Access
- AWX의 사용자 및 권한 관리 
- AWX의 권한은 조직 > 팀 > 유저 순으로 관리됨
- 권한 수정후 재 로그인해야 적용되므로 주의
    - Organizations
        - 조직 구성 및 권한 설정
        - 조직내의 속한 팀 및 유저의 권한을 설정가능
    - Teams
        - 팀 구성 및 권한 설정
        - 팀 별 권한 설정 가능 (유저 개인에 대한 설정은 불가)
    - Users
        - awx에서 사용가능한 계정을 추가
### Resource 
- Ansible 작업 관련 메뉴   
    - `Hosts`
        - Ansible 명령을 실행할  Host 목록
        
        - Manual로 직접 입력 혹은 Inventories에서 불러온 Host 목록을 저장
        
        - 로컬의 /etc/ansible/hosts 파일과는 다르며 동기화 x
    
    - `Inventories`
        - Hosts를 특정 그룹으로 묶어 정의
        
        - Ansible-inventory에서의 그룹과 동일한 역하
        
        - 로컬의 /etc/ansible/hosts 파일과는 다르며 동기화 x
        
        - 생성 후 Source를 추가 및 Credential을 지정하면 <br> GCP/AWS/Azure 등의 퍼블릭 클라우드 및 Openstack/Vcenter 등의 vm목록을 불러오기 가능
            
            - 불러온 vm들은 Hosts에 자동으로 추가
      
    - `Credentials`
        - Project 나 Inventories 등에 접근하기 위한 Credentials를 생성 및 관리
    - `Projects`
        - playbook yml 파일 목록을 관리
        - 로컬에 존재하는 파일이나 Git , 외부 저장소 주소 등을 연결하여 <br>
          playbook을 불러올수 있도록 하는 역할
    - `Templates`
        - playbook을 실행하는 Job을 만들어 관리 
        - 실행 후에도 삭제되지않음
## AWX 사용방법 - 기본 설정 및 사용
- 내부망에 존재하는 서버를 hosts 및 inventory로 지정
- 로컬에 존재하는 yml파일을 이용하여 ansible 실행
### 1. Credential 생성
- ssh 개인키 확인 후 추가
    - AWX서버에서 host에 ssh 접속이 가능하도록 미리 설정 필요
#### Create New Credential
|항목|값|
|:-:|:-|
|Name | ssh_key
|Description | ansible_ssh_key|
|Organization | Default|
|Credential Type | Machine|
#### Type Details
|항목|값|
|:-:|:-|
|Username | root|
|Password | [root_password]|
|SSH Private Key | AWX 서버 root 개인키|
### 2.Inventory 생성
- 이름 및 조직 지정 후 생성
#### Create new inventory
|항목|값|
|:-:|:-|
|Name|ansible_inventory|
|Organization| Default|
### 3.Inventory에 Hosts 추가
- 내부망의 경우 수동으로 추가 필요
- Name 에  IP 주소 입력 
- host를 추가할 Inventory 선택
#### Create New Host -1
|항목|값|
|:-:|:-|
|Name|192.168.1.6|
|Inventory| ansible_inventory|
#### Create New Host -2
|항목|값|
|:-:|:-|
|Name|192.168.1.9|
|Inventory| ansible_inventory|
    
### 4. Project 추가 
- 로컬 디스크 내의 yml파일을 불러옴
- /var/lib/awx/projects의 하위 폴더에 저장된 yml파일을 가져올수 있음
- `AWX에서 사용하는 yml파일의 host는 all로 지정해야함`
    
```bash
mkdir -p /var/lib/awx/projects
cd /var/lib/awx/projects
mkdir manual_test   
```
>vi hello.yml
```yml
---
 - name: test
   hosts: all
   gather_facts: false
   tasks:
     - name: test
       shell: echo 'hello'
       register: res
     - debug: var=res.stdout_lines
```
#### Create New Project
|항목|값|
|:-:|:-|
|Name| manual_directory |
|Organization| Default|
|Source Control Credential Type | manual |
|Playbook Directory| manual_test|
<br>

- `Playbook Direcoty 목록이 안뜨는경우 해결방법`
    
    - 설치시 사용한 inventory파일 확인 및 awx 계정생성 후,  <br>  /var/lib/awx/projects를 awx 유저 권한으로 부여해볼것
    
    - docker exec -it awx_web /bin/bash 로 접속후 /var/lib/awx/projects 확인 
<br>

### 5. Job Template 추가 
- Projects > Job Templates > add 혹은 Templates > add > add Job Template로 추가
- 변수 지정, tag지정, timeout 지정 등 다양한 옵션 지원
- Job Type 구분
    - run : playbook 실행
    - check : 실행 가능한지 check 작업만 수행
- Options
  
|옵션| 기능 |
|:-:|:-|
|Privilege Escalation|become (sudo) 기능|
|Enable Fact Storage|gather_fact 기능|
|Enable Webhook| Github 등에서 Webhook설정을 가능하게 함|
|Concurrent Jobs|Run하기 전에 Check 작업 수행 하여 Fail나지 않으면 진행|

#### Create New Job Template
|항목|값|
|:-:|:-|
|Name|ping_test|
|Description|ping_test|
|Job Type |run|
|Inventory|ansible_inventory|
|Project|manual_directory|
|Playbook|ping_test.yaml|
|Credentials|ssh_key|
        
- 저장 후 Launch로 실행하면 자동으로 결과창 으로 이동
## AWX 사용방법 - Git Repository 연동
- Project에 Git repository를 연동하여 repository내의 yml파일을 실행할 수 있음.
- github/gitlab Personal Access Token을 통해 연동 가능
### Git access token 발행   
- GITHUB    
    - Personal setting(프로필아이콘) > Developer Settings > Personal Access tokens
    - repo관련 권한 설정 후 생성
- GITLAB
    - Personal setting(프로필아이콘) >  Access tokens
    - repo관련 권한 설정 후 생성
### GIt Project 생성
- Credential 생성 후 project를 생성
- 이후 생성된 프로젝트에서 yml파일을 불러와서 job 생성 및 실행
- 
#### Create New Credential
- Github와 Gitlab이 구분되어있으므로 주의
  
|항목|값|
|:-:|:-|
|Name| git_hub_token|
|Organization| Default|
|Credential Type | GitHub Personal Access Token|
|token| [gihub/gitlab Access tokens]|
#### Create New Project
|항목|값|
|:-:|:-|
|Name| git_project |
|Organization| Default|
|Source Control Credential Type | git |
|Source Control URL| https://github.com/wocheon/1.Ansible.git|
- 생성 후 목록에서 Sync Project로 연동 진행
    - 왼쪽에 초록색 박스가 뜨면 연동 성공
#### Create New Job Template
|항목|값|
|:-:|:-|
|Name|git_job|
|Job Type |run|
|Inventory|ansible_inventory|
|Project|git_project|
|Playbook|Examples/pingtest.yml|
|Credentials|ssh_key|
>Examples/pingtest.yml
```yaml
---
- name: test
  hosts: all
  become: yes
  gather_facts: no
  tasks:
  - name: chck
    ping:
```
- 생성 후 Launch로 동작확인
## AWX 사용방법 - Git Webhook 설정
- github/gitlab에서 변경사항 발생시, webhook을 통해 job이 실행되도록 설정
- Template 단위로 지정
### Template webhook 설정 
- 이전 단계에서 생성한 git_job을 변경 
- 아래 옵션 부분의 Enable Webhook 체크하면 Webhook 설정부분이 나옴
#### Webhook details
- Webhook Service : Github
- webhook Credential : git_hub_token ( github access token)
- 저장을 한번 해야 webhook키가 생성됨
### Github webhook 설정
- repository setting > webhook
    - Payload URL : Webhook URL 입력
    - Content type : application/json
    - Secret : Webhook key 입력
- 생성 후 연결 확인
- 변경 후 커밋하면 자동으로 Job이 도는지 확인
## AWX 사용방법 - GCP Inventory 연동
- Google Compute Engine 
    - Service Account ADC file ( Json파일 ) 을 Credentail로 추가
### Create New Credential
- Github와 Gitlab이 구분되어있으므로 주의
항목|값|
|:-:|:-|
|Name| gcp_service_account_credential|
|Organization| Default|
|Credential Type |Google Compute Engine|
- Service account JSON file에 Json파일을 추가 후 저장
### GCP GCE Inventory 생성
#### Create new inventory
|항목|값|
|:-:|:-|
|Name|gcp_gce_list|
|Organization| Default|
- 생성 완료 후 목록에서 gcp_gce_list 클릭
    - Sources > add
        #### Create new source
        |항목|값|
        |:-:|:-|
        |Name| test-project|
        |Source| Google Compute Engine|
        - Source 선택시 자동으로 Credential 선택됨
- Source에서 Credential 추가시 자동으로 Host 등록
    - 외부주소로 Hosts에 추가됨
- 프로젝트 내의 모든 vm이 추가되므로 이를 Smart Inventory로 묶어서 사용
    - 다음 두 방법중 하나로 생성
        - Hosts에서 특정 host들만 체크하여 생성
        - gcp_gce_list 인벤토리에서 Group을 생성 후 add Smart Inventory에서 Group으로 검색하여 생성
### gcp용 smart inventory list 구성 및 job 실행
- os 별로 구분하여 그룹을 생성함
- ansible_all
    - ansible-awx
    - ansible-test-1
    - ansible-test-2
- ansible_centos
    - ansible-awx
    - ansible-test-1
- ansible_ubuntu
    - ansible-test-2
#### Create New Job Template
|항목|값|
|:-:|:-|
|Name|gcp_ansible_oscheck|
|Job Type |run|
|Inventory|gcp_ansible_all|
|Project|git_project|
|Playbook|Examples/oschck.yml|
|Credentials|ssh_key|
>Examples/oschck.yml
```yaml
---
 - name: OS check
   hosts: all
   become: yes
   gather_facts: no
   tasks:
   - name: os chck
     shell: |
       cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/\"//g'
     register: os_chck
   - name: set fact
     set_fact: os_chck={{ os_chck.stdout }}
   - name: print val
     debug:
       msg:
       - "{{ os_chck }}"
   - name: os chck ubuntu
     shell: |
       echo "Ubuntu"
     when: os_chck == "ubuntu"
     register: res_1
   - name: os chck cent
     shell: |
       echo "CentOS"
     when: os_chck != "ubuntu"
     register: res_2
   - name: debug_ubun
     debug: var=res_1.stdout_lines
     when : os_chck == "ubuntu"
   - name: debug_cent
     debug: var=res_2.stdout_lines
     when : os_chck != "ubuntu"
```
## AWX 사용방법 - Remote Archive
- 외부주소에서 특정 파일을 불러오는것이 가능 
- GCP Cloud Storage에서 공개엑세스 설정 후 접근 가능 
    - 스토리지 자체에 엑세스는 불가하고 파일 단위로만 접근 가능..
### 버킷 공개엑세스 설정 방법
- 구성원명 : allUsers
- 역할 : 저장소 개체 뷰어
### 신규 프로젝트 생성
- project
    - Name : gcp storage test
    - Source Control Credential Type : Remote Archive 
    - Source Control URL : 버킷 내의 파일의 공개 URL
- 생성 후 Sync로 제대로 불러오는지 확인
## AWX 사용방법 - workflow 기능
- 여러 job을 분기별로 구분하여 연속적으로 동작하게끔 만드는 기능
    - 이전 job의 성공 / 실패 여부 혹은 관계없이 다른 job이 실행되도록 설정 가능
- 특정 구간별로 승인 절차를 넣어서 승인되어야 다음 작업이 돌게끔 할수 있음
- 조직/팀/유저 설정을 통해 프로세스 절차를 구성가능
- 신규 조직 추가없이 팀 및 유저만 추가하여 구현
### 신규 Workflow Template 추가
#### Create New Workflow Template
|항목|값|
|:-:|:-|
|Name|workflow|
|Organization |Default|
|Inventory|gcp_ansible_all|
- 생성후 목록에서 클릭하여 Visualizer로 이동
#### Workflow 구성하기
- Start에서 + 버튼 클릭시 run type 지정가능 
    -  On Success : 이전 job 이 성공하면 실행할 Job 추가 (초록색)
    -  On Failure : 이전 job 이 실패하면 실행할 Job 추가 (빨간색)
    -  Always :  이전 job의 성공/실패 여부와 관계없이 실행할 Job 추가(파란색)
- 구성
    - Start => ping_req => ping_test => os_check_req => os_check
1. ping_req
    - Workflow Approval
    - ping_test job 실행 전 승인요청
2. ping_test
    - ping 모듈로 ping 확인
3. os_check_req
    - On Success로 os_check_req 추가
    - Workflow Approval
    - os_check job 실행 전 승인요청
4. os_check
    - shell 모듈로 os 확인 job
### 팀 및 유저 추가
#### 신규 유저 추가
- Username : ciw0707
- User Type : Normal User
#### 신규 팀 추가
- Name : user
- Organization : Default 
- 생성 후 목록에서 user 클릭
    - Roles > Add
        - 1.Add resource type : Workflow job templates
        - 2.Select items from list : workflow 선택
        - 3.Select roles to apply : Approve, Read 선택
- 신규 생성된 유저로 접속하여 workflow run을 진행
- ping_req, os_check_req 부분에서 admin계정이 승인 전까지 실행 중지됨
- admin 계정에서 Workflow Approvals에서 승인하면 다음단계로 진행됨
