#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

export SEC_GROUP_NAME=${SEC_GROUP_NAME:-${GROUP}-sec-group}
"${PROJECT_DIR}/ec2/create_sec_groups.sh"
"${PROJECT_DIR}/ec2/create_instances.sh" "$1"
"${PROJECT_DIR}/dns/create_dns_records.sh"

aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PublicIpAddress, PublicDnsName]" \
        --output text

printf "\n\nVMs are up an running\n"
printf "Please wait until the 'Status check' of every instance is OK,\n"

instance_ids=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text)

while true; do
  echo -e "$instance_ids" | xargs aws ec2 describe-instance-status --instance-ids \
  | yq -oy '.InstanceStatuses[] | (.InstanceStatus.Status == "ok" and .SystemStatus.Status == "ok")' \
  | grep --quiet --invert-match false

  if [[ "$?" = 0 ]]; then
    break
  fi
  echo "Waiting for the instances to be ready"
  sleep 10
done

printf "\nSetup the instances"
"${PROJECT_DIR}/ec2/setup_instances.sh"
