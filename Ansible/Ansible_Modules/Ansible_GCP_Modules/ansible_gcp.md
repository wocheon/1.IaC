# Ansible - GCP 연동

## 구성

### 작업용 VM 
- OS : CentOS or Ubuntu 
- Spec : 무관
- Ansible GCP 모듈 사용을 위해 외부와 통신 가능하도록 설정

### Ansible 설정
- host는 localhost로 설정하여 진행함
- ssh-keygen 후 공개키를 authorized_keys 파일에 입력하
     -  자기 자신에게 ssh 가능하도록 설정해야 Ansible host로 사용가능
- /etc/ansible/hosts 에 추가 
>vi /etc/ansible/hosts
```bash
[test]
127.0.0.1
```
- ansible all -m ping 으로 동작 확인

### google-auth
- Ubuntu
```bash
apt install -y python3-pip
pip install requests google-auth
```
-  RHEL / CentOS
```bash
yum install -y python-requests python2-google-auth.noarch
```


## Credentials 설정
- Ansible GCP 모듈로  GCP 프로젝트에 연결하기 위해서는 서비스 계정의 키 값이 필요.

- 다음 두가지 방법 중 하나로 키 값을 생성 가능
     1. 신규 Service Account 생성 후 키 생성
          - 신규 계정 생성 후, 역할 부여 등을 진행해야하므로 기존 계정 활용방법을 추천

     2. 기존 Service Account의 키 생성 

### 기존 Service Account의 키 생성 방법

`GCP Console`

- IAM 및 관리자  >  서비스 계정

- 이름 항목이 App Engine default service account인 계정 확인

- 해당 계정 정보에 들어가서 `키` 항목으로 이동

- 키 추가 
     - 키 유형 : JSON 
     - `키 생성시 자동으로 JSON 파일 다운로드됨.`

- 다운로드된 JSON 파일을 업로드 혹은 내용을 복사하여 사용


- 작업용 VM에 Credential 파일을 service-account.json 로 생성
>vi service-account.json

```json
{
  "type": "service_account",
  "project_id": "gcp-in-ca",
  ...
  ...
  ...
  "universe_domain": "googleapis.com"
}
```

## Ansible-GCP : 고정 IP 생성

### yml 파일 생성
>vi create_ip.yaml
```yml
- name: Create IP address
  hosts: localhost
  gather_facts: false

  vars:
    service_account_file: service-account.json
    project: gcp-in-ca
    auth_kind: serviceaccount
    scopes:
      - https://www.googleapis.com/auth/compute

  tasks:

   - name: Allocate an IP Address
     gcp_compute_address:
         state: present
         name: 'test-address1'
         region: 'asia-northeast3'
         project: "{{ project }}"
         auth_kind: "{{ auth_kind }}"
         service_account_file: "{{ service_account_file }}"
         scopes: "{{ scopes }}"
```         

### ansible-playbook 실행
```bash
$ ansible-playbook create_ip.yaml

PLAY [Create IP address] ***************************************************************************************

TASK [Allocate an IP Address] **********************************************************************************
changed: [127.0.0.1]

PLAY RECAP *****************************************************************************************************
127.0.0.1                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

### GCP 콘솔에서 확인 
- 정상적으로 생성되면 VPC > IP 주소에서  고정 외부 IP `test-address1` 를 확인 가능
     - 할당되지않은 상태이므로 확인 후 삭제


##  GCP - Ansible Dynamic Inventroy  연동

### Inventory 디렉토리 생성

```bash
cd /etc/ansible/
mkdir inventory
mv /root/service-account.json inventory/
```

### GCP_Compute inventory Plugin 작성

>vi gcp.yaml
```yaml
---
plugin: gcp_compute
projects:
  - gcp-in-ca
auth_kind: serviceaccount
service_account_file: /etc/ansible/inventory/service-account.json
filters:
  - labels.사용자:wocheon07
  #  - status = RUNNING
keyed_groups:
  - key: labels
    prefix: Label
  - key: status
    prefix: State
  - key: zone
    prefix: Zone
groups:
  development: "'k8s' in (labels|list)"
  staging: "'jenkins' in name"
#hostnames:
#  - name
```

### ansible.cfg 파일 수정

>vi /etc/ansible/ansible.cfg
```bash
[inventory]
#enable inventory plugins, default: 'host_list', 'script', 'auto', 'yaml', 'ini', 'toml'
enable_plugins = host_list, virtualbox, yaml, gcp_compute
# 해당 라인 주석 해제 후 gcp_compute 추가
```

### ansible-inventory 확인
```bash
$ ansible-inventory -i gcp.yaml --graph

@all:
  |--@Label_k8s_master:
  |  |--34.64.86.238
  |--@Label_k8s_worker:
  |  |--35.216.78.39
  |--@Label_사용자_wocheon07:
  |  |--34.22.77.236
  |  |--34.64.135.230
  |  |--34.64.86.238
  |  |--35.216.78.39
  |--@Label_용도_jenkins:
  |  |--34.64.135.230
  |--@Label_용도_k8s:
  |  |--34.64.86.238
  |  |--35.216.78.39
  |--@State_RUNNING:
  |  |--34.22.77.236
  |--@State_TERMINATED:
  |  |--34.64.135.230
  |  |--34.64.86.238
  |  |--35.216.78.39
  |--@Zone_asia_northeast3_b:
  |  |--34.64.86.238
  |  |--35.216.78.39
  |--@Zone_asia_northeast3_c:
  |  |--34.22.77.236
  |  |--34.64.135.230
  |--@development:
  |  |--34.64.86.238
  |  |--35.216.78.39
  |--@staging:
  |  |--34.64.135.230
  |--@ungrouped:
```

### Ansible Default inventory 변경

* ansible.cfg 파일 수정

>vi /etc/ansible/ansible.cfg
```bash
[defaults]
# some basic default values...
inventory      = /etc/ansible/inventory
```

*  적용 확인

```
ansible-inventory --list 

or 

ansible-inventory --graph

```


## Ansible - GCP 리소스 생성 

### 참고- GCP 리소스 문법
- https://docs.ansible.com/ansible/latest/collections/google/cloud/index.html#description

### GCP Disk 생성하기
```yaml
- name: Create an instance
  hosts: localhost
  gather_facts: false
  vars:
      gcp_project: gcp-in-ca
      gcp_cred_kind: serviceaccount
      gcp_cred_file: /etc/ansible/inventory/service-account.json
      zone: "asia-northeast1-a"
      region: "asia-northeast1"

  tasks:
   - name: create a disk
     gcp_compute_disk:
         name: 'ansible-disk-test'
         size_gb: 10
         #source_snapshot:
         #  selfLink: "projects/gcp-in-ca/global/snapshots/gitlab-snapshot-1"
         source_image: "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20230817"
         zone: "{{ zone }}"
         project: "{{ gcp_project }}"
         auth_kind: "{{ gcp_cred_kind }}"
         service_account_file: "{{ gcp_cred_file }}"
         scopes:
           - https://www.googleapis.com/auth/compute
         state: present
         labels:
           사용자: wocheon07
```

### GCP Instance 생성

```yaml
- name: Create an instance
  hosts: localhost
  gather_facts: false
  vars:
      gcp_project: gcp-in-ca
      gcp_cred_kind: serviceaccount
      gcp_cred_file: /etc/ansible/inventory/service-account.json
      zone: "asia-northeast1-a"
      region: "asia-northeast1"

  tasks:
  - name: create vm
    gcp_compute_instance:
      zone: "{{ zone }}"
      project: "{{ gcp_project }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ gcp_cred_file }}"
      state: present
      name: ansible-vm1
      machine_type: e2-micro
      labels:
        사용자: wocheon07
      disks:
        - auto_delete: true
          boot: true
#         source: "{{ disk }}"
          source:
            selfLink: "projects/gcp-in-ca/zones/asia-northeast1-a/disks/ansible-disk-test"
      network_interfaces:
        - network:
            selfLink: "projects/gcp-in-ca/global/networks/test-vpc-1"
          subnetwork:
            selfLink: "projects/gcp-in-ca/regions/asia-northeast1/subnetworks/test-vpc-sub-03"
          access_configs:
            - name: External NAT
              type: ONE_TO_ONE_NAT
      scopes:
        - https://www.googleapis.com/auth/compute
    register: instance

```


### GCP DISK, Static IP , Instance 동시 생성

```yaml
- name: Create an instance
  hosts: localhost
  gather_facts: false
  vars:
      gcp_project: my-project
      gcp_cred_kind: serviceaccount
      gcp_cred_file: my_account.json
      zone: "asia-northeast1"
      region: "asia-northeast1-a"

  tasks:
   - name: create a disk
     gcp_compute_disk:
         name: 'disk-instance'
         size_gb: 20
         source_image: 'ubuntu-2004-focal-v20230817'
         zone: "{{ zone }}"
         project: "{{ gcp_project }}"
         auth_kind: "{{ gcp_cred_kind }}"
         service_account_file: "{{ gcp_cred_file }}"
         scopes:
           - https://www.googleapis.com/auth/compute
         state: present
     register: disk
   - name: create a address
     gcp_compute_address:
         name: 'address-instance'
         region: "{{ region }}"
         project: "{{ gcp_project }}"
         auth_kind: "{{ gcp_cred_kind }}"
         service_account_file: "{{ gcp_cred_file }}"
         scopes:
           - https://www.googleapis.com/auth/compute
         state: present
     register: address
   - name: create a instance
     gcp_compute_instance:
         state: present
         name: test-vm
         machine_type: n1-standard-1
         disks:
           - auto_delete: true
             boot: true
             source: "{{ disk }}"
         network_interfaces:
             - network: null # use default
               access_configs:
                 - name: 'External NAT'
                   nat_ip: "{{ address }}"
                   type: 'ONE_TO_ONE_NAT'
         zone: "{{ zone }}"
         project: "{{ gcp_project }}"
         auth_kind: "{{ gcp_cred_kind }}"
         service_account_file: "{{ gcp_cred_file }}"
         scopes:
           - https://www.googleapis.com/auth/compute
     register: instance

   - name: Wait for SSH to come up
     wait_for: host={{ address.address }} port=22 delay=10 timeout=60

   - name: Add host to groupname
     add_host: hostname={{ address.address }} groupname=new_instances


- name: Manage new instances
  hosts: new_instances
  connection: ssh
  become: True
  roles:
    - base_configuration
    - production_server

```


### GCP VM 정보 확인 
``` yaml
- name: get vm info
  hosts: localhost
  gather_facts: false
  vars:
      gcp_project: gcp-in-ca
      gcp_cred_kind: serviceaccount
      gcp_cred_file: /etc/ansible/inventory/service-account.json
      zone: "asia-northeast3-c"
      region: "asia-northeast3"

  tasks:
  - name: get_vm_resource_info
    gcp_compute_instance_info:
      zone: "{{ zone }}"
      filters:
      - name = gcp-ansible
      project: "{{ gcp_project }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ gcp_cred_file }}"

    register: res

  - debug: var=res.resources[0]
```