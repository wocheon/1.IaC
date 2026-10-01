#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
partition="${SLURM_TEST_PARTITION:-compute}"

# srun 명령 옵션
#| 옵션           | 의미                       |
#| -------------- | -------------------------  |
#| srun            | Slurm에서 명령 실행        |
#| --job-name=...  | 작업 이름 지정             |
#| --partition=... | 사용할 Partition 지정      |
#| --nodelist=...  | 실행할 노드 직접 지정      |
#| --nodes=1       | 사용할 노드 수             |
#| --ntasks=1      | 실행할 Task(Process) 수    |
#| --chdir=...     | 실행 전 작업 디렉토리 이동 |
#| python3 ...     | 실제 실행할 명령           |


echo "# srun은 작업이 끝날 때까지 기다리며 결과를 현재 터미널에 출력합니다."
echo "- partition=${partition}, nodelist=slurm-compute-01"
srun \
  --job-name=slurm-srun-example \
  --partition="${partition}" \
  --nodelist=slurm-compute-01 \
  --nodes=1 \
  --ntasks=1 \
  --chdir="${script_dir}" \
  python3 "${script_dir}/slurm_smoke_test.py"
echo ""

echo "- partition=${partition}, nodelist=slurm-compute-02"
srun  \
  --job-name=slurm-srun-example-2 \
  --partition="${partition}" \
  --nodelist=slurm-compute-02 \
  --nodes=1 \
  --ntasks=1 \
  --chdir="${script_dir}" \
  python3 "${script_dir}/slurm_smoke_test.py"