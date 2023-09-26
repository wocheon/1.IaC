# Ansible AWX

## AWX
- ansible tower 의 오픈소스 버전으로,
ansible 을 GUI 로 관리하고, api 로 제어할 수 있도록 해주는 시스템.

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
admin_password=admin 
#해당라인 주석 해제 후 패스워드 변경

# Local directory that is mounted in the awx_postgres docker container to place the db in
# 경로를 절대경로로 변경
postgres_data_dir="/root/.awx/pgdocker"
host_port=80
host_port_ssl=443
#ssl_certificate=
# Optional key file
#ssl_certificate_key=
docker_compose_dir="/root/.awx/awxcompose"
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
   