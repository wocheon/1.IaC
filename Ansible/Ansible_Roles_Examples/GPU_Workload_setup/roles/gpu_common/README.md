# gpu_common

네 개의 GPU 환경 Role이 공유하는 내부 기반 Role이다. Ubuntu 검증, 설치 전 preflight, NVIDIA Driver, CUDA Toolkit, 선택적 cuDNN, NVIDIA Container Toolkit 패키지 설치와 재부팅 판정을 담당한다.

일반적으로 직접 적용하지 않고 `gpu_standalone`, `gpu_docker`, `gpu_kubernetes`, `gpu_slurm`을 사용한다. 각 환경 Role은 `include_role`을 통해 필요한 컴포넌트만 활성화한다.

주요 내부 선택 변수는 `gpu_common_install_driver`, `gpu_common_install_cuda`, `gpu_common_install_cudnn`, `gpu_common_install_nvidia_container_toolkit`이다. 버전과 안전성 변수는 `defaults/main.yml`에 정의되어 있으며 Play나 inventory에서 덮어쓸 수 있다.

`preflight.yml`은 Secure Boot, kernel headers, nouveau/NVIDIA module, 기존 Driver, NVIDIA device node, root filesystem 여유 공간과 CUDA/Driver 최소 branch를 읽기 전용으로 확인한다. `gpu_preflight_enabled: false`로 비활성화할 수 있다.
