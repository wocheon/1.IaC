#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

printf 'Host\tIP\n'
ansible-inventory -i inventory.yaml --list | jq -r '._meta.hostvars | to_entries[] | "\(.key)\t\(.value.ansible_host // "-")"'

printf '\nGroup membership\n'
ansible-inventory -i inventory.yaml --graph
