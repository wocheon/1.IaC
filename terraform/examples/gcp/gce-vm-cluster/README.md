# GCP Kubernetes/Slurm VM 클러스터 테스트

기존 `web-1`, `was-1`과 동일한 `gce_instance` 모듈로 control plane 1대와 node 2대를 생성합니다.

- 새 VPC, 서브넷, NAT, 방화벽은 생성하지 않습니다.
- 기존 `test-vpc-1`, `test-vpc-sub-01`을 사용합니다.
- `terraform.tfvars`도 기존 VM 디렉터리와 같은 단일 값 형식입니다.
- node 이름은 `vm_name` 뒤에 `1`, `2`를 붙여 만들고, control plane 이름은 `control_plane_vm_name`을 사용합니다.
- custom hostname을 지정하지 않고 GCE 기본 동작으로 VM 이름을 OS hostname으로 사용합니다.
- `internal_ip`을 control plane에 할당하고 node에는 그 다음 IP부터 순서대로 할당합니다.
- 세 VM 모두 `e2-medium`과 Ubuntu 24.04 LTS NVIDIA 595 드라이버 이미지를 사용합니다.
- Terraform을 실행하는 현재 로컬 계정의 `~/.ssh/id_rsa.pub` 공개키를 세 VM의 동일 사용자 계정에 등록합니다.
- 다른 사용자명이나 공개키를 사용하려면 `ssh_user`, `ssh_public_key_path`를 지정합니다. 개인키는 VM에 복사하지 않습니다.

```bash
cd terraform/gce-vm-cluster
terraform init
terraform plan
terraform apply
```

현재 설정에서는 아래 VM 3대가 생성됩니다.

- `gcp-an3-a-cluster-control-plane` (`192.168.1.30`)
- `gcp-an3-a-cluster-node1` (`192.168.1.31`)
- `gcp-an3-a-cluster-node2` (`192.168.1.32`)

적용 전에 해당 이름과 IP가 기존 리소스에서 사용 중이지 않은지만 확인하면 됩니다.
