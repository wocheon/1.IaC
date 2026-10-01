#!/bin/bash

# Slurm 클러스터 정보
echo "# Slurm Cluster Info"
sinfo --Node --long

#현재 queue 목록
echo "# Slurm Queue Lists"
squeue