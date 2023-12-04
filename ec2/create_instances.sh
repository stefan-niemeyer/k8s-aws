#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

NUM_VMS=${1:-$NUM_VMS}
if [[ -n "$NUM_VMS" ]]; then
  VM_NAMES_NUM=$(seq -f "${GROUP}-%g" "$NUM_VMS")
fi

if [[ -n "$VM_NAMES_FILE" ]]; then
  VM_NAMES_PLAIN=$(cat "$VM_NAMES_FILE")
fi

# Get Security Group ID
SEC_GROUP_NAME=${SEC_GROUP_NAME:-${GROUP}-sec-group}
SEC_GROUP_ID=$(aws ec2 describe-security-groups --group-names "${SEC_GROUP_NAME}" --query 'SecurityGroups[*].GroupId' --output text)

# Create the EC2 instances
for VM_NAME in $VM_NAMES_NUM $VM_NAMES_PLAIN; do
  echo "Create EC2 instance '${VM_NAME}'"
  aws ec2 run-instances \
        --image-id ami-06dd92ecc74fdfb36 \
        --count 1 \
        --instance-type t2.large \
        --key-name aws-ssh-sn-azubi-lab \
        --security-group-ids "${SEC_GROUP_ID}" \
        --subnet-id subnet-05ccf1e5f801bceb3 \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${VM_NAME}},{Key=group,Value=${GROUP}}]" > /dev/null
done

echo "Wait for all instances to be in the state 'running'"
aws ec2 wait instance-running \
        --filters "Name=instance-state-name,Values=running,pending" "Name=tag:group,Values=${GROUP}"
