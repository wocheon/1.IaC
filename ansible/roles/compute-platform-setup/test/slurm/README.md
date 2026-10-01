# Slurm 테스트 스크립트

테스트는 Slurm 전용 사용자 `slurmuser`로 실행한다. 스크립트는 공유 NFS의
`/mnt/slurm/scripts`, `sbatch` 출력은 `/mnt/slurm/outputs`에 저장된다.

```bash
sudo -iu slurmuser
cd /mnt/slurm/scripts
```

기본 partition은 `compute`이고 테스트 프로그램은 3초 동안 실행된다. 필요한
경우 실행할 때만 값을 변경할 수 있다.

```bash
SLURM_TEST_PARTITION=compute SLURM_TEST_SLEEP=10 ./run_sbatch_test.sh
```

## slurm_cluster_check.sh

클러스터의 노드 상태와 현재 큐를 간단히 확인한다.

```bash
./slurm_cluster_check.sh
```

- `sinfo --Node --long`: controller가 인식한 노드와 상태
- `squeue`: 대기하거나 실행 중인 Job

## run_srun_test.sh

`srun`으로 Python 테스트를 실행하고 완료될 때까지 기다린다. 결과는 현재
터미널에 바로 출력된다.

```bash
./run_srun_test.sh
```

현재 구성에 맞춰 `slurm-compute-01`, `slurm-compute-02`에서 각각 한 번씩
실행한다. 각 실행은 노드 1개와 task 1개를 사용한다.

## run_gpu_srun_test.sh

`salloc`으로 CPU 1개, 메모리 256MB와 GPU 1개를 할당받은 뒤, 할당 안에서
`srun`으로 `nvidia-smi`를 실행한다. Slurm GPU worker에 NVIDIA 드라이버와
GRES 설정이 먼저 구성되어 있어야 한다.
`slurm_gpu_node_setup.yaml` → `slurm_cluster_setup.yaml` →
`slurm_gpu_cluster_setup.yaml` 순서로 GPU host, 기본 클러스터, GPU 자원을 구성한다.

```bash
./run_gpu_srun_test.sh
```

정상 실행되면 할당된 노드, `CUDA_VISIBLE_DEVICES`, GPU 정보가 현재 터미널에
출력된다. GPU가 Slurm에 등록됐는지는 다음 명령으로 확인할 수 있다.

```bash
sinfo --Node --Format=NodeList,Gres,GresUsed
```

## run_salloc_test.sh

CPU 1개와 메모리 256MB를 대화형 작업용으로 할당받고, 할당된 자원 안에서
`srun`으로 Python 테스트를 실행한다. 특정 노드를 지정하지 않으므로 Slurm이
실행할 노드를 선택한다.

```bash
./run_salloc_test.sh
```

테스트가 끝나면 `salloc`의 자원 할당도 반환된다.

## run_sbatch_test.sh

하나의 batch Job을 큐에 제출한다. Job은 compute 노드 2개를 할당받아 각
노드에서 task 1개씩, 총 2개의 Python 테스트를 동시에 실행한다.

```bash
./run_sbatch_test.sh
```

스크립트는 Job ID를 출력한 뒤 해당 Job의 `squeue` 상태를 한 번 보여준다.
`sbatch`는 Job 완료를 기다리지 않으므로 이후 상태는 Job ID로 확인한다.

```bash
squeue --jobs=<job-id>
```

표준 출력은 다음 파일에 저장된다.

```bash
cat /mnt/slurm/outputs/slurm-sbatch-<job-id>.out
```

`slurm_accounting_enabled: true`로 SlurmDBD/MariaDB Accounting이 구성된
환경에서는 스크립트가 `sacct` 결과도 보여준다. Job이 끝난 뒤에도 이력을
다시 확인할 수 있다.

```bash
sacct --jobs=<job-id> --format=JobID,JobName,State,ExitCode,NodeList
```

Accounting이 비활성화된 환경에서는 `sacct` 대신 위의 NFS 출력 파일을
확인하라는 안내가 표시된다.

## slurm_smoke_test.py

세 실행 예제가 공통으로 호출하는 테스트 프로그램이다. 시작과 완료 시점에
스크립트 이름, task rank, 실행 노드, Job ID를 출력하므로 어느 노드에서
실행됐는지 바로 확인할 수 있다.

```text
[slurm_smoke_test.py] 시작 rank=0 node=slurm-compute-01 job_id=42
[slurm_smoke_test.py] 완료 rank=0 node=slurm-compute-01 job_id=42
```

## 현재 배포 설정

- 사용자: `slurmuser` (`UID:GID` = `2000:2000`)
- 클러스터: `compute-cluster`
- 기본 partition: `compute`
- 스크립트: `/mnt/slurm/scripts`
- batch 출력: `/mnt/slurm/outputs`
- Accounting: `slurm_accounting_enabled` 값에 따라 구성

테스트 파일은 NFS에만 배포되며 `/home/slurmuser`에는 복사하지 않는다.
