#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

if [[ -z "$VM_USER" || -z "$VM_ID_FILE"  || -z "$LAB_USER"  || -z "$LAB_PASSWD" ]]; then
  echo "The file .env or the environment needs to contain settings, see README.md"
  exit 1
fi

set -e     # exit script if a command fails

VMS=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PublicDnsName]" \
        --output text)

while read line; do
  if [[ -z "$line" ]]; then
    continue
  fi

  VM_HOST=$(echo $line | cut -d" " -f1)
  PUBLIC_DNS=$(echo $line | cut -d" " -f2- | tr -d " ")
  printf "\n\nVM_HOST: ${VM_HOST}\n"
  echo "PUBLIC_DNS: ${PUBLIC_DNS}"

  echo "Initializing '${VM_HOST}'"
  scp -i "${VM_ID_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "${PROJECT_DIR}"/vm-scripts/* "${VM_USER}@${PUBLIC_DNS}:"
  ssh -i "${VM_ID_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -n "${VM_USER}@${PUBLIC_DNS}" sudo ./initialize.sh
  ssh -i "${VM_ID_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -n "${VM_USER}@${PUBLIC_DNS}" sudo hostname "${VM_HOST}"
  ssh -i "${VM_ID_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -n "${VM_USER}@${PUBLIC_DNS}" sudo ./create_user.sh "${LAB_USER}" "${LAB_PASSWD}"
done <<< "${VMS}"
