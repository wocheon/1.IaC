# GCP 영구 디스크 Cloud Storage 이관

## 개요 
- 기존 GCE vm에서 사용중인 영구디스크를 Cloud Storage로 전환

- 작업 대상 서버가 다수이므로 ansible,expect등의 자동화 툴을 사용하여 작업

- 패키지 설치시 root권한이 필요함
    - sudo 권한이 있는경우 sudo로 처리하면 되지만 sudo가 불가능한 상황으로 가정함.
    - root 권한을 획득하기 위해 expect 스크립트를 작성하여 사용

- OS 로그인이 되어있는 상태이므로 ansible에서 root계정 사용이 불가능한 상황

- 각 서버별로 crontab 작업이 걸려있으므로 서버별로 gcsfuse uid,gid를 설정하여 마운트


### 필요 패키지 목록
- Ansible
- Expect
- Gcsfuse
- google-cloud-sdk

## 작업순서 
1. Cloud Storage 연결을 위한 gcsfuse 설치 
    - gcsfuse repo 추가
    - gcsfuse 패키지 설치 

2. gcsfuse를 통해 Cloud Storage를 NFS 형태로 마운트 

3. 서버 중지 후 API 권한 - 저장소 권한을 변경 <br>
   혹은 GCP ADC 권한 인증을 통해 저장소 권한을 획득

4. 영구 디스크 데이터를 Cloud Storage에 이관 


## Cloud Stoage 연결을 위한 gcsfuse 패키지 설치 + NFS 형태로 마운트
- 다음 3가지 스크립트를 작성하여 Ansible-playbook으로 대상서버에 스크립트 복사를 진행.

### install_expect.sh
- expect 설치용 스크립트 
- 해당스크립트는 Ubuntu에서 사용이 불가
    - Ubuntu 서버는 root계정으로 expect를 직접 설치
```bash
#!/bin/bash
ip=$(hostname -i | gawk '{print $1}')
host_nm=$(hostname | gawk -F'_' '{print $1}')

if [ $host_nm == 'test' ] || [ $host_nm = 'dev' ]; then
    pass="welcome1"
else
     pass="prod$(hostname -i | gawk '{print $1}' | gawk -F'.' '{print $4}')"
fi     

su - << EOF
${pass}
yum install -y expect
EOF
```

### expect_su.sh
- expect를 통해 root로 로그인하여 스크립트를 실행
```bash
#!/bin/bash

script_path=$1

ip=$(hostname -i | gawk '{print $1}')
host_nm=$(hostname | gawk -F'_' '{print $1}')

if [ $host_nm == 'test' ] || [ $host_nm = 'dev' ]; then
    pass="welcome1"
else
     pass="prod$(hostname -i | gawk '{print $1}' | gawk -F'.' '{print $4}')"
fi

expect << EOF
spawn su 
expect "Password:"
sleep 1
send "$pass\n"
send "sh $script_path; exit;\n"
expect eof
EOF

exit
```

### gcsfuse.sh
- gcsfuse 설치용 스크립트
- ubuntu와 CentOS 는 각각 gcsfuse 설치방법이 다르므로 구분함
- 설치 후 /etc/fstab에 기록 하여 영구 마운트 진행

```bash
os=$(cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/\"//g')
ip=$(hostname -i | gawk '{print $1}')
host_nm=$(hostname | gawk -F'_' '{print $1}')

if [ $host_nm == 'test' ] || [ $host_nm = 'dev' ]; then
    pass="welcome1"
    gcsfuse_uid=$(id -u ciw0707)
    gcsfuse_gid=$(id -g ciw0707)
else
     pass="prod$(hostname -i | gawk '{print $1}' | gawk -F'.' '{print $4}')"
    gcsfuse_uid=$(id -u p_ciw0707)
    gcsfuse_gid=$(id -g p_ciw0707)
fi

# install gcsfuse
gcsfuse -v 
if [ $? -ne 0 ]; then
    if [ $os != 'ubuntu' ]; then
        cat << EOF > /etc/yum.repos.d/gcsfuse.repo 
        [gcsfuse]
        name=gcsfuse (packages.cloud.google.com)
        baseurl=https://packages.cloud.google.com/yum/repos/gcsfuse-el7-x86_64
        enabled=1
        gpgcheck=1
        repo_gpgcheck=0
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
              https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
        EOF

        yum install -y gcsfuse
    else
        export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
        echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

        apt-get update -y; apt-get install -y gcsfuse
    fi
else
    echo "gcsfuse Already Installed!"
fi

# Mount Google Cloud Storage by GCSFUSE
gcsfuse -v
if [ $? -eq 0 ]; then
    mkdir -p /GCP_Storage
    echo "gcp-in-ca-test-bucket-wocheon07 /GCP_Storage gcsfuse rw,_netdev,allow_other,uid=${gcsfuse_uid},gid=${gcsfuse_gid}" >> /etc/fstab
    mount -a 
    ls -lrth /GCP_Storage
    df -Th
else
    echo "Install gcsfuse Failed!"    
fi
```

### Script 복사용 Ansible-Playbook
```yaml
- name: copy script
  hosts: gcsfuse
  gather_facts: no
  vars: 
    copy_path: /home/ciw0707/
    expect_script: expect_su.sh
    file_nm_1: install_expect.sh
    file_nm_2: gcsfuse.sh
  tasks:
    - name: copy expect script
      copy: 
        src: "scripts/{{ expect_script }}"
        dest: "{{ copy_path }}{{ expect_script }}"
        mode: 0755

    - name: copy script scirpt file_1
      copy: 
        src: "scripts/{{ file_nm_1 }}"
        dest: "{{ copy_path }}{{ file_nm_1 }}"
        mode: 0755        

    - name: copy script scirpt file_2
      copy: 
        src: "scripts/{{ file_nm_2 }}"
        dest: "{{ copy_path }}{{ file_nm_2 }}"
        mode: 0755        

    - name: ls copy path 
      shell: |
        ls -lrth {{ copy_path }}
      register: res
      
    - debug: var=res.stdout_lines
```

### 스크립트 실행순서 
- 대상 서버가 많은 경우 스크립트 실행시 디버깅을 용이하게 하기위해 나누어서 진행

1. expect 설치 진행
2. expect 스크립트로 root 계정 접속 후 gcsfuse 설치 스크립트 진행

### expect 설치용 스크립트 실행 
>run_script.yaml
```yaml
- name: run install expect script
  hosts: gcsfuse
  gather_facts: no
  vars:
    copy_path: /home/ciw0707/
    file_nm: install_expect.sh
  
  tasks:
    - name: scripts exist chck
      shell: | 
        ls -lrth 
      register: res_1
    
    - name: debug_1
      debug: var=res_1.stdout_lines

    - name: sh script
      shell: | 
        sh {{ file_nm }}
      register: res_2   

    - name: debug_2
      debug: var=res_2.stdout_lines
```

### expect 스크립트로 root 계정 접속 후 gcsfuse 설치 스크립트 실행
>run_expect_script.yaml
```yaml
- name: run expect script
  hosts: gcsfuse
  gather_facts: no
  vars:
    copy_path: /home/ciw0707/
    expect_script: expect_su.sh
    file_nm: gcsfuse.sh
  tasks:
    - name: run script by expect_su.sh 
      shell: | 
        sh {{ expect_script }} '{{ copy_path }}{{ file_nm }}'
    
    - name: check result
      shell: ls -lrth /GCP_Storage
      register: res 
    - name: debug
      debug: var=res.stdout_lines
```

### 작업 결과 확인 
- mount 시 allow_other 옵션을 주어 다른계정에서도 읽기 작업은 가능 
- 쓰기 작업 권한 부여는 ADC 인증까지 해야 가능함
    - mount 한 uid,gid와 동일한 계정이 아니면 파일 생성 불가
    - root도 불가능


```yaml
- name: chck pkg & result
  hosts: gcsfuse
  gather_facts: no
  vars:
    pkg_nm_1: gcsfuse
    pkg_nm_2: expect
  
  tasks:
    - name: os chck
      shell: |
        cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/\"//g'
      register: os_chck
      changed_when: os_chck.rc != 0
      ignore_error: true
    
    - name: set fect - os  
      set_fact: os_chck={{ os_chck.stdout }}
    
    - name : chck pkg - Ubuntu
      shell: |
        dpkg -l | egrep -e '{{ pkg_nm_1 }}|{{ pkg_nm_2 }})'
        ls -lrth /GCP_Storage
      when: os_chck == 'ubuntu'
      register: res_1

    - name: debug - Ubuntu
      debug: var=res_1.stdout_lines
      when: os_chck == 'ubuntu'

    - name : chck pkg - CentOS
      shell: |
        rpm -qa | egrep -e '{{ pkg_nm_1 }}|{{ pkg_nm_2 }})'
        ls -lrth /GCP_Storage
      when: os_chck != 'ubuntu'
      register: res_2

    - name: debug - CentOS
      debug: var=res_2.stdout_lines
      when: os_chck != 'ubuntu'
```

## GCP ADC 권한 인증
- GCE vm의 API 권한 중 저장소 권한이 읽기 권한으로 설정되어있는 경우 (기본엑세스)
    - Cloud Storage를 마운트하더라도 읽기 작업만 가능함

### gcloud auth application-default login
- 웹브라우저를 통해 ADC 인증을 진행함.
    - --no-browser 옵션을 주면 웹브라우저에서 띄우지 않고 서버상에서 띄울수 있는 명령어를 출력
    
- 해당 인증 진행시 API권한 변경없이 Cloud Storage 에 읽기 , 쓰기 권한을 가질 수 있음
        - 재부팅 필요 없음
    
- Application-Default-Credential 파일
    - 서비스 계정의 key값을 생성하여 JSON 파일 형태로 저장
        
- 기본 저장 위치 
    - $HOME/.config/gcloud
        - gcloud info로 위치 확인 가능
        - 해당 디렉토리가 없는경우 gcloud info 명령실행하면 자동으로 디렉토리 생성
        - 해당위치에 application_default_credentials.json 파일로 저장하면 자동으로 인증

- 동일 프로젝트에 존재하는 vm은 동일한 서비스계정을 가지므로 한 서버에서 인증을 진행한 뒤, <br>  다른 서버에 JSON 파일을 복사하는 형태로 사용이 가능함.


```bash
$ gcloud auth application-default login

You are running on a Google Compute Engine virtual machine.
The service credentials associated with this virtual machine
will automatically be used by Application Default
Credentials, so it is not necessary to use this command.

If you decide to proceed anyway, your user credentials may be visible
to others with access to this virtual machine. Are you sure you want
to authenticate with your personal account?

Do you want to continue (Y/n)?  Y

Go to the following link in your browser:
# 아래 링크에 접속하여 google 계정으로 인증 > google auth libray 허용
    https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fsdk.cloud.google.com%2Fapplicationdefaultauthcode.html&scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth&state=pWUPiQYj7CpQt3hfmYxGfTGpDi9xaP&prompt=consent&access_type=offline&code_challenge=EDGUdX6e54ZG8rzjLqY6rSbEOwzby3QU3gty03lrdQo&code_challenge_method=S256

# 브라우저에 나온 authorization code를 복사하여 입력
Enter authorization code: 4/0Adeu5BWHzCczjFkTdOlLWmp9f4ET4u4AZ187ozgJEkKGWVQN7i80SJ5SLgxDZn1GH4XfOQ

Credentials saved to file: [/root/.config/gcloud/application_default_credentials.json]

These credentials will be used by any library that requests Application Default Credentials (ADC).

Quota project "gcp-in-ca" was added to ADC which can be used by Google client libraries for billing and quota. Note that some services may still bill the project owning the resource.


$ ls -lrth /root/.config/gcloud/application_default_credentials.json
-rw-------. 1 root root 330 Sep  7 05:16 /root/.config/gcloud/application_default_credentials.json
```
    
## ADC 인증 파일 복사 + 재마운트 진행용 스크립트 작성
- ADC 인증파일 복사 후 재마운트 진행
- 완료후 root 계정으로 마운트된 Cloud Storage에 log파일을 생성
```bash
#!/bin/bash
gcloud info 
ls -l /root/.config/gcloud 

if [ $? -eq 0 ]; then
    cp /home/ciw0707/application_default_credentials.json /root/.config/gcloud
    fusermount -u /GCP_Storage
    mount -a 
    touch /GCP_Storage/adc_logs/$(hostname)_$(hostname -i).log
else
    "cp ADC failed"
fi
```
## ADC 인증용 Ansible-playbook 작성 
- /GCP_Storage/adc_logs 에서 log 파일 확인 
> cp_gcp_ADC.yaml
```yaml
- name: copy GCP ADC file 
  hosts: gcsfuse
  gather_facts: no
  vars:
    copy_path: /home/ciw0707/
    expect_script: expect_su.sh
    script_file: cp_gcp_adc.sh
    adc_file: application_default_credentials.json
  
  tasks:
    - name: copy expec script
      copy:
        src: "scripts/{{ expect_script }}"
        dest: "{{ copy_path }}{{ expect_script }}"
        mode: 755

    - name: copy script file
      copy:
        src: "scripts/{{ script_file }}"
        dest: "{{ copy_path }}{{ script_file }}"
        mode: 755

    - name: copy adc
      copy:
        src: "scripts/{{ adc_file }}"
        dest: "{{ copy_path }}{{ adc_file }}"
        mode: 755        

    - name: run script file
      shell: | 
        sh {{ expect_script }} '{{ copy_path }}{{ script_file }}'
    
    - name: check result 
      shell: |
        ls -lrth /GCP_Storage/adc_logs
      register: res

    - name: debug result
      debug:
        msg:
          - "{{ res.stdout_lines }}"

```