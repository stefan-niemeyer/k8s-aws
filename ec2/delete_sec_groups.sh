#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

set -e     # exit script if a command fails

SEC_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=tag:group,Values=${GROUP}" \
        --query 'SecurityGroups[*].GroupId' \
        --output text)

printf "\nDelete security groups\n"
while read sec_group; do
  if [[ -z "$sec_group" ]]; then
    continue
  fi

  printf "\nDeleting Security Group '${sec_group}'\n"
  aws ec2 delete-security-group --group-id "${sec_group}"
done <<< "${SEC_GROUPS}"
