#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

set -e     # exit script if a command fails

"${PROJECT_DIR}/dns/delete_dns_records.sh"

"${PROJECT_DIR}/ec2/delete_instances.sh"
while true; do
  running=$(aws ec2 describe-instances --filters "Name=tag:group,Values=${GROUP}" "Name=instance-state-name,Values=running,pending,shutting-down,stopping,stopped" | yq '.Reservations | length')
  if [[ "${running}" = 0 ]]; then
    break
  fi
  echo "There are still $running instances not terminated"
  sleep 10
done

"${PROJECT_DIR}/ec2/delete_sec_groups.sh"
