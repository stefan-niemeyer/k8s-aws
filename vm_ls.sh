#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PublicIpAddress, PublicDnsName]" \
        --output text
