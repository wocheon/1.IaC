# gpu_docker

NVIDIA Driver, Docker Engine, NVIDIA Container Toolkit과 Docker GPU runtime을 구성한다. 호스트 CUDA Toolkit과 cuDNN은 설치하지 않으며 CUDA runtime은 컨테이너 이미지가 제공한다.

```yaml
- hosts: gpu_docker_hosts
  become: true
  roles:
    - role: gpu_docker
      vars:
        docker_users:
          - ubuntu
```

설치 후 `docker run --rm --gpus all <CUDA_IMAGE> nvidia-smi`로 확인할 수 있다. `docker_manage_daemon_json: true`이면 Role이 `/etc/docker/daemon.json` 전체를 관리한다.

DCGM Exporter 컨테이너는 기본 비활성이다. 사용할 경우 NVIDIA 지원 매트릭스에서 확인한 고정 tag를 지정해야 한다.

```yaml
gpu_install_dcgm_exporter: true
dcgm_exporter_image: "nvcr.io/nvidia/k8s/dcgm-exporter:<고정-tag>"
```
