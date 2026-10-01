#!/usr/bin/env bash
set -euo pipefail

nvidia-smi
"${GPU_PYTHON_VENV_PATH:-/opt/gpu-venv}/bin/python" -c \
  'import torch; print("CUDA:", torch.cuda.is_available()); print(torch.cuda.get_device_name(0))'
