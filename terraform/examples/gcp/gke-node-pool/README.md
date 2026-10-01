# 기존 GKE 클러스터용 노드풀

`examples/`에서 필요한 유형의 Terraform 파일 3개를 저장소 루트로 복사한 뒤 값을 수정해 사용합니다. 공통 구현은 `modules/gke-node-pool/`에 있습니다.

| 예제 | 기본 구성 | 서울 기본 존 |
| --- | --- | --- |
| `examples/n1-t4-gpu/` | `n1-standard-4` + NVIDIA T4 | `asia-northeast3-b` |
| `examples/g2-gpu/` | `g2-standard-4` + NVIDIA L4 | `asia-northeast3-a` |
| `examples/n4/` | `n4-standard-4` | `asia-northeast3-a` |
| `examples/e2-n2-general/` | `e2-standard-4` 또는 N2 | `asia-northeast3-a` |

기본 provider 리전과 클러스터 위치는 `asia-northeast3`입니다. GPU의 실제 생성 가능 여부는 존별 quota와 재고에도 영향을 받습니다.

## 사용 방법

예를 들어 N1 + T4 구성을 사용하려면 저장소 루트에서 실행합니다.

```bash
cp examples/n1-t4-gpu/main.tf .
cp examples/n1-t4-gpu/variable.tf .
cp examples/n1-t4-gpu/terraform.tfvars .

# terraform.tfvars의 project_id, cluster_name과 필요한 옵션을 수정
gcloud auth application-default login
terraform init
terraform fmt -check
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

다른 유형을 사용하려면 복사 경로만 바꿉니다. 예제 안의 모듈 경로는 루트 실행을 기준으로 `./modules/gke-node-pool`로 되어 있으므로 `examples/` 내부에서 직접 `terraform init`하지 않습니다.

각 `terraform.tfvars`에서 다음 설정을 바로 수정할 수 있습니다.

- `kubernetes_labels`: Kubernetes node label
- `kubernetes_taints`: Kubernetes taint와 effect
- `network_tags`: Compute Engine 방화벽용 네트워크 태그
- `resource_labels`: `{}`이면 사용자 GCP 리소스 라벨을 추가하지 않음

서비스 계정, OAuth scope, gVNIC, GCFS처럼 생략 가능한 값은 예제에서 주석 처리되어 있습니다. 서비스 계정을 생략하면 GKE가 프로젝트의 Compute Engine 기본 서비스 계정을 사용합니다. 운영 환경에서는 최소 권한의 전용 노드 서비스 계정을 사용하는 것이 권장됩니다.

## GCE 인스턴스 메타데이터

`instance_metadata`를 생략하면 Terraform이 `metadata`를 API에 보내지 않으며, GKE 1.12 이상에서 API가 적용하는 `disable-legacy-endpoints=true` 기본값을 그대로 사용합니다.

다른 메타데이터가 필요해 `instance_metadata` 맵을 지정하면 공통 모듈이 `disable-legacy-endpoints=true`를 자동 병합합니다. 이는 metadata 맵을 설정하면서 해당 키를 누락할 경우 Terraform이 API 기본값을 해제하려 할 수 있다는 Google provider의 주의사항을 피하기 위한 처리입니다.

기본 `deletion_policy`는 `PREVENT`입니다. 삭제가 필요하면 `DELETE`로 바꾸고 먼저 `terraform apply`하여 정책 변경을 상태에 반영합니다.

## 참고 문서

- [Terraform google_container_node_pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool)
- [GKE 노드 서비스 계정](https://cloud.google.com/kubernetes-engine/docs/how-to/service-accounts)
- [Compute Engine GPU 위치](https://cloud.google.com/compute/docs/regions-zones/gpu-regions-zones)
- [GKE Standard에서 GPU 실행](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus)
- [GKE 노드 이미지](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images)
