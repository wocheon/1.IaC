#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
partition="${SLURM_TEST_PARTITION:-compute}"

echo "# salloc은 자원을 할당받은 뒤 그 안에서 명령을 실행합니다."
echo "- partition=${partition}, cpus=1, memory=256M"
salloc \
  --job-name=slurm-salloc-example \
  --partition="${partition}" \
  --ntasks=1 \
  --cpus-per-task=1 \
  --mem=256M \
  srun --chdir="${script_dir}" python3 "${script_dir}/slurm_smoke_test.py"
