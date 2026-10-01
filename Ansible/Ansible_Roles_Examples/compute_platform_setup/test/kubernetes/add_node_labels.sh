#!/usr/bin/env bash
set -euo pipefail

mapfile -t control_planes < <(
  kubectl get nodes -l 'node-role.kubernetes.io/control-plane' -o name | sed 's#^node/##'
)
mapfile -t workers < <(
  kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name | sed 's#^node/##'
)
nodes=("${control_planes[@]}" "${workers[@]}")

if (( ${#nodes[@]} < 3 || ${#workers[@]} < 2 )); then
  echo "control plane 1대와 worker 2대 이상이 필요합니다." >&2
  exit 1
fi

if [[ "${1:-apply}" == "cleanup" ]]; then
  for node in "${nodes[@]}"; do
    kubectl label node "${node}" deploy-test- || true
    kubectl label node "${node}" test-node- || true
  done
  exit 0
fi

for index in "${!nodes[@]}"; do
  kubectl label node "${nodes[$index]}" "deploy-test=node-$((index + 1))" --overwrite
done

for index in "${!workers[@]}"; do
  printf -v worker_label 'worker-%02d' "$((index + 1))"
  kubectl label node "${workers[$index]}" "test-node=${worker_label}" --overwrite
done
