# Prepare

## Python 3.8 설치
- ansible 설치를 위해 python3.8이상 버전을 설치

```
yum install gcc openssl-devel bzip2-devel libffi-devel
wget https://www.python.org/ftp/python/3.8.9/Python-3.8.9.tgz
# tar xvfz Python-3.8.9.tgz 
# cd Python-3.8.9
# ./configure --enable-optimizations
# make altinstall

# python -V
Python 3.8.9
```    

## Ansible 설치 
- 기존 ansible 패키지가 있는 경우 삭제 필요

- pip로 ansible 설치 
```
# pip3.8 install ansible 
```

## Playbook 실행 시 필요 모듈 설치 
- ansible-galaxy를 통해 필요 모듈 설치 
```
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
```

