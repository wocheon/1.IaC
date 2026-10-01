#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
output_dir="$(dirname "${script_dir}")/outputs"
partition="${SLURM_TEST_PARTITION:-compute}"

echo "# sbatch는 작업을 큐에 제출하고 Job ID를 반환한 뒤 바로 종료합니다."
echo "- partition=${partition}, nodes=2, ntasks=2"
job_id="$(
  sbatch --parsable \
    --job-name=slurm-sbatch-example \
    --partition="${partition}" \
    --nodes=2 \
    --ntasks=2 \
    --ntasks-per-node=1 \
    --chdir="${script_dir}" \
    --output="${output_dir}/slurm-sbatch-%j.out" \
    --wrap="srun --nodes=2 --ntasks=2 --ntasks-per-node=1 python3 ${script_dir}/slurm_smoke_test.py"
)"
job_id="${job_id%%;*}"

echo "# 제출된 Job ID: ${job_id}"
squeue --jobs="${job_id}"

if scontrol show config | grep -q 'AccountingStorageType.*slurmdbd'; then
  sacct --jobs="${job_id}" --format=JobID,JobName,State,ExitCode,NodeList
  echo "# 완료 후에도 같은 sacct 명령으로 작업 이력을 확인할 수 있습니다."
else
  echo "# 실행 결과: ${output_dir}/slurm-sbatch-${job_id}.out"
fi
