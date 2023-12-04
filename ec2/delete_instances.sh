#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

set -e     # exit script if a command fails

VMS=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], InstanceId]" \
        --output text)

printf "\nTerminate EC2 instances\n"
while read line; do
  if [[ -z "$line" ]]; then
    continue
  fi

  VM_HOST=$(echo $line | cut -d" " -f1)
  INSTANCE_ID=$(echo $line | cut -d" " -f2- | tr -d " ")
  printf "\n\nVM_HOST: ${VM_HOST}\n"
  printf "INSTANCE_ID: ${INSTANCE_ID}\n"

  printf "Terminating '${VM_HOST}'\n"
  aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}" > /dev/null
done <<< "${VMS}"
