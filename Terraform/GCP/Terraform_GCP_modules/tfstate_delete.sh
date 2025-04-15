#!/bin/bash
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

find ./* -name terraform.tfstate* -exec rm -rf {} \;
find ./* -name .terraform* -exec rm -rf {} \;

#find ./* -name terraform.tfstate* 
#find ./* -name .terraform* 
