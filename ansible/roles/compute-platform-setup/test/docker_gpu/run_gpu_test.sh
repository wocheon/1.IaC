#!/usr/bin/env bash
set -euo pipefail

sudo docker run --rm --gpus all \
  "${CUDA_IMAGE:-nvidia/cuda:12.6.3-base-ubuntu24.04}" nvidia-smi
