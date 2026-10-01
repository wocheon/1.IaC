# Ansible을 통한 GCP VM 관리 
## 개요
- 테스트 환경 구성을 위해 동일한 세팅의 VM을 여러대 생성 필요

- ansible을 통해 한번에 여러 VM을 생성/중지/삭제 가능하도록 playbook을 작성

## Ansible 설정
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
  "project_id": "test-project",
  ...
  ...
  ...
  "universe_domain": "googleapis.com"
}
```

## GCP 리소스 접근 확인 
- GCP vm 정보를 가져오는 모듈로 Playbook 작성

```yml
- name: get vm info
  hosts: localhost
  gather_facts: false
  vars:
      gcp_project: test-project
      gcp_cred_kind: serviceaccount
      gcp_cred_file: "{{ playbook_dir }}/service-account.json"
      zone: "asia-northeast3-c"
      region: "asia-northeast3"

  tasks:
  - name: get_vm_resource_info
    gcp_compute_instance_info:
      zone: "{{ zone }}"
      filters:
      - name = gcp-ansible-test
      project: "{{ gcp_project }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ gcp_cred_file }}"

    register: res

  - debug: var=res.resources[0]
```
### 실행결과

```
[root@gcp-ansible-test create_vms]# ansible-playbook gcp_vm_check.yaml

PLAY [get vm info] **********************************************************************************

TASK [get_vm_resource_info] *************************************************************************
ok: [127.0.0.1]

TASK [debug] ****************************************************************************************
ok: [127.0.0.1] => {
    "res.resources[0]": {
        "canIpForward": false,
        "confidentialInstanceConfig": {
            "enableConfidentialCompute": false
        },
        "cpuPlatform": "Intel Broadwell",
        "creationTimestamp": "2024-01-24T22:13:40.313-08:00",
        "deletionProtection": false,
        "description": "",
        "disks": [
            {
                "architecture": "X86_64",
                "autoDelete": true,
                "boot": true,
                "deviceName": "base-centos7-template",
                "diskSizeGb": "20",
                "guestOsFeatures": [
                    {
                        "type": "UEFI_COMPATIBLE"
                    },
                    {
                        "type": "GVNIC"
                    }
                ],
                "index": 0,
                "interface": "SCSI",
                "kind": "compute#attachedDisk",
                "licenses": [
                    "https://www.googleapis.com/compute/v1/projects/centos-cloud/global/licenses/centos-7"
                ],
                "mode": "READ_WRITE",
                "source": "https://www.googleapis.com/compute/v1/projects/test-project/zones/asia-northeast3-c/disks/gcp-ansible-test",
                "type": "PERSISTENT"
            }
        ],
        "displayDevice": {
            "enableDisplay": false
        },
        "fingerprint": "tXsd_XAdb7s=",
        "id": "4473622970691764988",
        "keyRevocationActionType": "NONE",
        "kind": "compute#instance",
        "labelFingerprint": "UiNqVIjZJCw=",
        "labels": {
            "ì‚¬ìš©ìž": "wocheon07"
        },
        "lastStartTimestamp": "2024-01-29T23:44:24.536-08:00",
        "lastStopTimestamp": "2024-01-29T00:51:11.517-08:00",
        "machineType": "https://www.googleapis.com/compute/v1/projects/test-project/zones/asia-northeast3-c/machineTypes/e2-medium",
        "metadata": {
            "fingerprint": "MlOSYzT9nK8=",
            "items": [
                {
                    "key": "startup-script",
                    "value": "sudo -i << EOF\necho \"root:welcome1\" | /sbin/chpasswd\necho \"wocheon07:welcome1\" | /sbin/chpasswd\nsed -i 's/=enforcing/=disabled/g' /etc/selinux/config ; setenforce 0\nsystemctl disable firewalld --now\nsed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config\nsed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config\nsystemctl restart sshd\nyum install -y git curl wget ansible bash-completion\necho \"$(hostname -i) $(hostname)\" >> /etc/hosts\nEOF"
                }
            ],
            "kind": "compute#metadata"
        },
        "name": "gcp-ansible-test",
        "networkInterfaces": [
            {
                "accessConfigs": [
                    {
                        "kind": "compute#accessConfig",
                        "name": "External NAT",
                        "natIP": "34.64.134.194",
                        "networkTier": "PREMIUM",
                        "type": "ONE_TO_ONE_NAT"
                    }
                ],
                "fingerprint": "yZh4r01m8Dw=",
                "kind": "compute#networkInterface",
                "name": "nic0",
                "network": "https://www.googleapis.com/compute/v1/projects/test-project/global/networks/test-vpc-1",
                "networkIP": "192.168.1.21",
                "stackType": "IPV4_ONLY",
                "subnetwork": "https://www.googleapis.com/compute/v1/projects/test-project/regions/asia-northeast3/subnetworks/test-vpc-sub-01"
            }
        ],
        "reservationAffinity": {
            "consumeReservationType": "ANY_RESERVATION"
        },
        "scheduling": {
            "automaticRestart": true,
            "onHostMaintenance": "MIGRATE",
            "preemptible": false,
            "provisioningModel": "STANDARD"
        },
        "selfLink": "https://www.googleapis.com/compute/v1/projects/test-project/zones/asia-northeast3-c/instances/gcp-ansible-test",
        "serviceAccounts": [
            {
                "email": "487401709675-compute@developer.gserviceaccount.com",
                "scopes": [
                    "https://www.googleapis.com/auth/devstorage.read_only",
                    "https://www.googleapis.com/auth/logging.write",
                    "https://www.googleapis.com/auth/monitoring.write",
                    "https://www.googleapis.com/auth/servicecontrol",
                    "https://www.googleapis.com/auth/service.management.readonly",
                    "https://www.googleapis.com/auth/trace.append"
                ]
            }
        ],
        "shieldedInstanceConfig": {
            "enableIntegrityMonitoring": true,
            "enableSecureBoot": false,
            "enableVtpm": true
        },
        "shieldedInstanceIntegrityPolicy": {
            "updateAutoLearnPolicy": true
        },
        "startRestricted": false,
        "status": "RUNNING",
        "tags": {
            "fingerprint": "42WmSpB8rSM="
        },
        "zone": "https://www.googleapis.com/compute/v1/projects/test-project/zones/asia-northeast3-c"
    }
}

PLAY RECAP ******************************************************************************************
127.0.0.1                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```


## VM 관리용 Playbook 작성
- disk 생성 후 VM을 생성하는 형태로 작성
- gcp_commpute_disk 와 gcp_commpute_instance 모듈 사용
     - 참고 : https://docs.ansible.com/ansible/latest/collections/google/cloud/gcp_compute_instance_module.html

- 외부 변수 파일 사용 
     - 변수는 배열 형태로 작성하여 반복문으로 작동하게끔 작성
     - 외부 변수 파일 내에 서버 리스트 작성 후 해당 파일에서 VM 및 disk의 상태를 결정

### 외부변수 파일 작성

>vm_list.yaml

```yaml
#### gcp service-account file ###
gcp_cred_kind: serviceaccount
gcp_cred_file: service-account.json

### GCP Project & Regions ###
gcp_project: test-project
region: "asia-northeast1"
zone: "asia-northeast1-a"

###GCE_VM_Network###
network : projects/test-project/global/networks/test-vpc-1
subnetwork : projects/test-project/regions/asia-northeast1/subnetworks/test-vpc-sub-03 #192.168.3.0/24

###GCE_VM_List###
vm_list:
  - vm_name: master-01
    vm_ip : 192.168.3.100
    machine_type: e2-small
    boot_disk_name: master-001
    boot_disk_size: 50
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: false
    vm_onoff: absent
    vm_status: absent

  - vm_name: worker-01
    vm_ip : 192.168.3.101
    machine_type: e2-micro
    boot_disk_name: worker-01-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: present
    vm_status: RUNNING

  - vm_name: worker-02
    vm_ip : 192.168.3.102
    machine_type: e2-micro
    boot_disk_name: worker-02-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: present
    vm_status: TERMINATED

  - vm_name: worker-03
    vm_ip : 192.168.3.103
    machine_type: e2-micro
    boot_disk_name: worker-03-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent

  - vm_name: worker-04
    vm_ip : 192.168.3.104
    machine_type: e2-micro
    boot_disk_name: worker-04-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent

  - vm_name: worker-05
    vm_ip : 192.168.3.105
    machine_type: e2-micro
    boot_disk_name: worker-05-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent
```     

### GCP disk 및 VM 관리용 Playbook 작성
- state : vm의 존재 여부를 결정
- status : vm의 동작 상태를 결정 (RUNNING , TERMINATED)
     - SUSPENDED 는 Ansible에서 사용불가 메세지 출력
- disk - source의 경우 배열변수로 받아야하므로 disk 파라미터를 받을 수없고 selfLInk 형태로 입력되도록 작성

- 추가디스크가 필요한 경우 disk 부분을 추가해야하므로 별도의 Playbook작성 필요

```yml
- name: manage an instance
  hosts: localhost
  gather_facts: false
  vars_files: vm_list.yaml

  tasks:

  - name: manage disk
    gcp_compute_disk:
      project: "{{ gcp_project }}"
      zone: "{{ zone }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ playbook_dir}}/{{ gcp_cred_file }}"
      scopes:
        - https://www.googleapis.com/auth/compute
      labels:
        user: wocheon07

      name: "{{ item.boot_disk_name }}"
      state: "{{ item.vm_onoff }}"
      size_gb: "{{ item.boot_disk_size }}"
      source_image: "{{ item.boot_disk_image }}"
        #source_snapshot:
         # selfLink: "{{ disk_snapshot }}"
    register: disk
    with_items:
      "{{ vm_list }}"

  - name: manage vm instance
    gcp_compute_instance:
      zone: "{{ zone }}"
      project: "{{ gcp_project }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ playbook_dir}}/{{ gcp_cred_file }}"
      state: "{{ item.vm_onoff }}"
      deletion_protection: no
      status: "{{ item.vm_status }}"
      name: "{{ item.vm_name }}"
      machine_type: "{{ item.machine_type }}"
      labels:
        user: wocheon07
      disks:
        - auto_delete: true
          boot: true
          source:
            selfLink: "https://www.googleapis.com/compute/v1/projects/{{ gcp_project }}/zones/{{ zone }}/disks/{{ 
tem.boot_disk_name }}"
      network_interfaces:
        - network:
            selfLink: "{{ network }}"
          subnetwork:
            selfLink: "{{ subnetwork }}"
          network_ip: "{{ item.vm_ip }}"
          access_configs:
            - name: External NAT
              type: ONE_TO_ONE_NAT
      scopes:
        - https://www.googleapis.com/auth/compute
    register: instance
    with_items:
      "{{ vm_list }}"
```

### 실행결과

```
[root@gcp-ansible-test create_vms]# ansible-playbook gcp_create_vm.yml

PLAY [Create an instance] ***************************************************************************************************************************************

TASK [create a disk] ********************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': _onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status''vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

TASK [create vm] ************************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': _onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_sto', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_sticro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

PLAY RECAP ******************************************************************************************************************************************************
127.0.0.1                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[root@gcp-ansible-test create_vms]# ansible-playbook gcp_create_vm.yml

PLAY [Create an instance] ***************************************************************************

TASK [create a disk] ********************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.                                                            168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small',                                                             u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot                                                            _disk_size': 50})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-micro                                                            ', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'                                                            boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'TERMINATED', u'machine_type': u'e2-mi                                                            cro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image',                                                             u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})

TASK [create vm] ************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.                                                            168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small',                                                             u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot                                                            _disk_size': 50})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'                                                            192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-                                                            micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image                                                            ', u'boot_disk_size': 20})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'                                                            192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'TERMINATED', u'machine_type': u'                                                            e2-micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-im                                                            age', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.1                                                            68.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro'                                                            , u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'bo                                                            ot_disk_size': 20})

PLAY RECAP ******************************************************************************************
127.0.0.1                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0                                                                ignored=0
```

### 결과 정리 

#### disk
- master-01 : 생성되지않음 (state: absent)
- worker-01 : 정상적으로 생성완료
- worker-02 : 정상적으로 생성완료
- worker-03 : 생성되지않음 (state: absent)
- worker-04 : 생성되지않음 (state: absent)
- worker-05 : 생성되지않음 (state: absent)

<img src="disk결과.PNG" width="80%" height="130">

#### VM
- master-01 : 생성되지않음 (state: absent)
- worker-01 : 정상적으로 RUNNING 상태로 기동됨
- worker-02 : 생성 완료 후 TERMINATED(중지) 상태로 변경 확인
- worker-03 : 생성되지않음 (state: absent)
- worker-04 : 생성되지않음 (state: absent)
- worker-05 : 생성되지않음 (state: absent)

<img src="vm결과.PNG" width="90%" height="130">

## VM 상태 변경 
- 중지상태인 vm을 재시작
  - worker-02의 vm_status 키 값을 running으로 변경

```yml
  - vm_name: worker-01
    vm_ip : 192.168.3.101
    machine_type: e2-micro
    boot_disk_name: worker-01-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent
#    vm_onoff: present
#    vm_status: RUNNING

  - vm_name: worker-02
    vm_ip : 192.168.3.102
    machine_type: e2-micro
    boot_disk_name: worker-02-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent
#    vm_onoff: present
#    vm_status: RUNNING
```


### 실행결과
```
[root@gcp-ansible-test create_vms]# ansible-playbook gcp_create_vm.yaml

PLAY [Create an instance] ************************************************************************************************************************************************************************************

TASK [create a disk] *****************************************************************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

TASK [create vm] *********************************************************************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'RUNNING', u'machine_type': u'e2-micro', u'vm_onoff': u'present', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

PLAY RECAP ***************************************************************************************************************************************************************************************************
127.0.0.1                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

<img src="vm결과_2.PNG" width="90%" height="130">

- worker-02 정상기동 확인


## 삭제 처리 
- 생성된 vm 전체 삭제 처리 진행
     - worker-01/worker-02의 vm_onoff, vm_status 키 값을 absent로 변경

```yml
  - vm_name: worker-01
    vm_ip : 192.168.3.101
    machine_type: e2-micro
    boot_disk_name: worker-01-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent
#    vm_onoff: present
#    vm_status: RUNNING

  - vm_name: worker-02
    vm_ip : 192.168.3.102
    machine_type: e2-micro
    boot_disk_name: worker-02-001
    boot_disk_size: 20
    boot_disk_image: projects/test-project/global/images/ansible-image
    boot_disk_auto_delete: true
    vm_onoff: absent
    vm_status: absent
#    vm_onoff: present
#    vm_status: RUNNING
```

### 삭제용 playbook 작성
- 삭제시 vm 먼저 삭제후 disk가 삭제 되어야하므로 기존 생성 및 관리 파일과 다르게 작성 필요
     - 추후에 disk 상태를 체크해서 하나의 playbook으로 사용가능하게끔 변경예정

>gcp_delete_vm.yaml
```yml
- name: delete vm instances
  hosts: localhost
  gather_facts: false
  vars_files: vm_list.yaml

  tasks:
  - name: delete instances
    gcp_compute_instance:
      project: "{{ gcp_project }}"
      zone: "{{ zone }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ playbook_dir }}/{{ gcp_cred_file }}"
      scopes:
        - https://www.googleapis.com/auth/compute
      state: absent
      name: "{{ item.vm_name }}"
    with_items:
      "{{ vm_list }}"


  - name: delete remain boot disk
    gcp_compute_disk:
      project: "{{ gcp_project }}"
      zone: "{{ zone }}"
      auth_kind: "{{ gcp_cred_kind }}"
      service_account_file: "{{ playbook_dir }}/{{ gcp_cred_file }}"
      scopes:
        - https://www.googleapis.com/auth/compute
      name: "{{ item.boot_disk_name }}"
      state: absent
    register: disk
    with_items:
      "{{ vm_list }}"
```


### 실행결과 

```
[root@gcp-ansible-test delete_vms]# ansible-playbook gcp_delete_vm.yml

PLAY [delete vm instances] ******************************************************************************************************************************************

TASK [delete instances] *********************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
changed: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

TASK [delete remain boot disk] **************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'vm_name': u'master-01', u'boot_disk_auto_delete': False, u'vm_ip': u'192.168.3.100', u'boot_disk_name': u'master-001', u'vm_status': u'absent', u'machine_type': u'e2-small', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 50})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-01', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.101', u'boot_disk_name': u'worker-01-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-02', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.102', u'boot_disk_name': u'worker-02-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-03', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.103', u'boot_disk_name': u'worker-03-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-04', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.104', u'boot_disk_name': u'worker-04-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})
ok: [127.0.0.1] => (item={u'vm_name': u'worker-05', u'boot_disk_auto_delete': True, u'vm_ip': u'192.168.3.105', u'boot_disk_name': u'worker-05-001', u'vm_status': u'absent', u'machine_type': u'e2-micro', u'vm_onoff': u'absent', u'boot_disk_image': u'projects/test-project/global/images/ansible-image', u'boot_disk_size': 20})

PLAY RECAP **********************************************************************************************************************************************************
127.0.0.1                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

- worker-01/worker-02 모두 삭제 확인