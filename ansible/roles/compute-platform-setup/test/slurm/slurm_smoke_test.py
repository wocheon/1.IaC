#!/usr/bin/env python3

import os
import socket
import time

hostname = socket.gethostname().split(".", maxsplit=1)[0]
job_id = os.environ.get("SLURM_JOB_ID", "unknown")
rank = os.environ.get("SLURM_PROCID", "unknown")
sleep_seconds = float(os.environ.get("SLURM_TEST_SLEEP", "3"))

print(
    "[slurm_smoke_test.py] 시작 "
    f"rank={rank} "
    f"node={hostname} "
    f"job_id={job_id}",
    flush=True,
)
time.sleep(sleep_seconds)
print(
    "[slurm_smoke_test.py] 완료 "
    f"rank={rank} "
    f"node={hostname} "
    f"job_id={job_id}",
    flush=True,
)
