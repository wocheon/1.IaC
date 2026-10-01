# Ansible-Vault

## Ansible-Vault

- Ansible 설치시 같이 설치됨

- 변수와 파일을 암호화해주는 역할

- 암호화된 파일을 생성 혹은 기존 파일을 암호화 

- ansible-vault 명령을 사용해 설정한 암호를 입력하면 복호화

- 암호화 알고리즘 
    - AES256


## Ansible Vault로 암호화된 파일 생성

### 암호화된 yml파일 생성

```bash
$ ansible-vault create vault_test.yml

New Vault password: #[passwd 입력]
Confirm New Vault password: #[passwd 입력]
```

- 암호 설정하면 자동으로 vi 에디터가 열림

>vault_test.yml
```yml
#ping test용 playbook 작성
 - name: test
   hosts: all
   become: yes
   gather_facts: no
   tasks:
   - name: test
     ping:
```

### 기존 yml파일 암호화 하기
```bash
$ ansible-vault encrypt oschck.yaml oschck_2.yaml
New Vault password: #[password]
Confirm New Vault password: #[password]
Encryption successful

#기존파일은 그대로 두고 암호화된 파일을 생성
$ ansible-vault encrypt --output=internet_encrypted.yml internet.yml
```

### 패스워드 파일을 이용하여 암호화 진행
- 패스워드 파일을 사용하여 암호화 진행이 가능

- 패스워드 파일을 사용하여 암호화 하더라도 직접 입력해서 실행가능

- 지정된 패스워드 파일은 평문 상태로 유지되므로 주의할것

```bash
#패스워드 파일 생성
echo "Password123$" > vault_passfile

#패스워드 파일을 사용하여 신규 파일 생성
ansible-vault create vault_test.yml --vault-password-file vault_passfile

#패스워드 파일을 사용하여 기존파일 암호화
ansible-vault encrypt oschck.yaml --vault-password-file vault_passfile

#패스워드 파일 변경
ansible-vault rekey --new-vault-password-file=pwfile test_encrypt.yml
```


## Ansible Vault로 암호화된 파일 읽기 및 수정

### 생성된 암호화된 yml파일 확인 (view)
```bash
$ ansible-vault view vault_test.yml
Vault password:
---
 - name: test
   hosts: all
   become: yes
   gather_facts: no
   tasks:
   - name: test
     ping:
```


### 생성된 암호화된 yml파일 편집(edit)

```bash
$ ansible-vault edit vault_test.yml
Vault password:
# 비밀번호 입력하면 자동으로 vi에디터로 열림
```


## Ansible Vault로 암호화된 파일 실행
```bash
$ ansible-playbook vault_test.yml
ERROR! Attempting to decrypt but no vault secrets found
# vault-id 옵션을 주지않으면 입력 창 없이 다음 에러가 발생함
```
- vault-id 옵션 추가 

```bash
$ ansible-playbook vault_test.yml --vault-id @prompt

Vault password (default): #[password]

PLAY [test] **************************************************************************

TASK [test] **************************************************************************
ok: [192.168.1.89]

PLAY RECAP ***************************************************************************
192.168.1.89               : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

#비밀번호 입력창이 뜨고 일치하면 정상적으로 실행됨
```

- 패스워드 불일치 시

```bash
$ ansible-playbook vault_test.yml --vault-id @prompt
Vault password (default): #[잘못된 password 입력]

ERROR! Decryption failed (no vault secrets were found that could decrypt) on /root/vault_test.yml
#다음과 같이 에러 발생하면서 실행되지않는다.
```

## 파일 복호화 및 패스워드 변경


### 영구적으로 암호화된 파일 복호화(decrypt)
```
$ ansible-vault decrypt oschck.yaml oschck_2.yaml
Vault password:
Decryption successful
```

### 암호화된 파일의 비밀번호 변경(rekey)
```
$ ansible-vault rekey oschck.yaml oschck_2.yaml
Vault password:
New Vault password:
Confirm New Vault password:
Rekey successful
```
<br>

## 특정 문자열만 암호화
### var test용 yml파일 작성

```yml
- name: var test
  hosts: all
  become: true
  gather_facts: no
  vars:
   var1: test

  tasks:
    - name: echovar
      shell: |
        echo "{{ var1 }}"
      register: res

    - name: print val
      debug:
        msg:
          - "{{ res.stdout }}"
```


### var1 부분을 암호화
- 다음 명령어를 통해 `var1: test` 부분을 암호화된 값으로 출력

```bash
#패스워드 파일 미지정시 직접 암호 입력필요
$ ansible-vault encrypt_string 'test' --name 'var1' --vault-password-file vault_passfile
var1: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30623962323134613934326365393634356330326266613838653934343065373264343936643633
          3263303364366334396132326563393862613539333737610a396563626331623430303035303963
          30646331616265323531313561646336636139346361643466393961626539386235376234346662
          6432326362316338660a313534303861303762386130633936383732656534353732626230366136
          3631
```

### 출력된 암호화 값을 yml파일에 적용

```yml
- name: var test
  hosts: all
  become: true
  gather_facts: no
  vars:
   #var1: test
   var1: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30623962323134613934326365393634356330326266613838653934343065373264343936643633
          3263303364366334396132326563393862613539333737610a396563626331623430303035303963
          30646331616265323531313561646336636139346361643466393961626539386235376234346662
          6432326362316338660a313534303861303762386130633936383732656534353732626230366136
          3631
  tasks:
    - name: echovar
      shell: |
        echo "{{ var1 }}"
      register: res

    - name: print val
      debug:
        msg:
          - "{{ res.stdout }}"
```

### 패스워드파일 사용하여 정상작동확인

```bash
$ ansible-playbook --vault-password-file vault_passfile var_test.yml

PLAY [var test] ************************************************************************************************

TASK [echovar] *************************************************************************************************
changed: [192.168.1.89]

TASK [print val] ***********************************************************************************************
ok: [192.168.1.89] => {
    "msg": [
        "test"
    ]
}

PLAY RECAP *****************************************************************************************************
192.168.1.89               : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```