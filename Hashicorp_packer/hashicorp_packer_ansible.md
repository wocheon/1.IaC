# Packer & Ansible 

## 개요 
- Pakcer를 통해 이미지 생성시 Provisioner를 Ansible로 사용할 수 있음 
- Ansible-playbook을 실행하여 이미지를 세팅하고 이를 사용 가능 


## 사용 조건 
- Source 부분의 remote_user 는 'root'를 사용 
    - 'gather_fact: true'인 경우 /root/.ansible/tmp 경로에 임시 디렉토리를 생성하려고 시도함
    - root계정이 아닌 경우 해당 부분에서 Permission Denied가 발생할 수 있음 
        - hcl파일의 Provisoner 부분에 become 옵션을 써봤으나 불가능
        - Playbook 파일에서 become 옵션을 사용해도 불가능

- Playbook의 hosts는 all 혹은 default로 설정 
    - localhost로 지정하는 경우 packer를 실행하는 VM에서 Playbook이 실행됨 

- hcl파일의 Provisioner - extra_arguments 에서 Inventory를 명시 
    - packer-provisioner-ansible이 제공하는 인벤토리 파일을 사용
```h
  extra_arguments = [
    "--inventory", "inventory"
  ]
```

- 변수 지정용 yml파일을 사용하는 경우 extra-vars로 지정 필요 

```h
  extra_arguments = [
    "--extra-vars", "@ansible-playbooks/var_list.yml"    
  ]
```