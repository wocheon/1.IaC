#!/usr/bin/env bash
set -euo pipefail

partition="${SLURM_TEST_PARTITION:-compute}"

echo "# salloc으로 GPU 1개를 할당받고 srun으로 nvidia-smi를 실행합니다."
echo "- partition=${partition}, cpus=1, memory=256M, gpu=1"
salloc \
  --job-name=slurm-gpu-test \
  --partition="${partition}" \
  --nodes=1 \
  --ntasks=1 \
  --cpus-per-task=1 \
  --mem=256M \
  --gres=gpu:1 \
  srun --ntasks=1 --gres=gpu:1 bash -c '
    echo "# Slurm GPU Task"
    echo "- node=$(hostname -s)"
    echo "- CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
    nvidia-smi
  '
