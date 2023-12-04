#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

SEC_GROUP_NAME=${SEC_GROUP_NAME:-${GROUP}-sec-group}

printf "\nCreate security group '${SEC_GROUP_NAME}'\n"

# Create the security group
aws ec2 create-security-group \
          --group-name "${SEC_GROUP_NAME}" \
          --description "K8s Workshop Security Group" \
          --vpc-id vpc-0b28fb2fb5b7f61cf \
          --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${SEC_GROUP_NAME}},{Key=group,Value=${GROUP}}]" > /dev/null

# Allow SSH (Port 22) from anywhere
aws ec2 authorize-security-group-ingress --group-name "${SEC_GROUP_NAME}" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null

# Allow HTTP (Port 80) from anywhere
aws ec2 authorize-security-group-ingress --group-name "${SEC_GROUP_NAME}" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null

# Allow Egress to anywhere
SEC_GROUP_ID=$(aws ec2 describe-security-groups --group-names "${SEC_GROUP_NAME}" --query 'SecurityGroups[*].GroupId' --output text)
aws ec2 authorize-security-group-egress --group-id "${SEC_GROUP_ID}" --protocol -1 --port all --cidr 0.0.0.0/0 &> /dev/null || true
