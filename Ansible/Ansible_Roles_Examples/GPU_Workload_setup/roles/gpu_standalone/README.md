# gpu_standalone

일반 VM에 NVIDIA Driver, CUDA Toolkit, 선택적 cuDNN과 Python virtualenv 기반 PyTorch/TensorFlow 환경을 구성한다.

```yaml
- hosts: gpu_vms
  become: true
  roles:
    - role: gpu_standalone
      vars:
        gpu_install_pytorch: true
        gpu_install_tensorflow: false
```

프레임워크는 `/opt/gpu-venv`에 설치된다. `pytorch_version`과 `tensorflow_version`이 빈 값이면 pip가 버전을 선택하며, 재현성이 필요한 환경에서는 버전을 명시해야 한다.

Host DCGM은 기본적으로 설치하지 않는다. 필요하면 `gpu_install_dcgm: true`로 활성화하며, 장시간 진단은 workload를 비운 뒤 `dcgm_run_diagnostics: true`로 별도 실행한다.
