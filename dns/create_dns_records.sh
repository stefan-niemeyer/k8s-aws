#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=laserschwert.io" \
               -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
               -H "Content-Type: application/json" \
          | yq -oy '.result[0].id')

VMS=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:group,Values=${GROUP}" \
        --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PublicIpAddress]" \
        --output text)

while read line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  VM_HOST=$(echo $line | cut -d" " -f1)
  PUBLIC_IP=$(echo $line | cut -d" " -f2- | tr -d " ")
  printf "\n\nVM_HOST: ${VM_HOST}\n"
  printf "PUBLIC_IP: ${PUBLIC_IP}\n"

  curl --request POST -s \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{
    "content": "'${PUBLIC_IP}'",
    "name": "'${VM_HOST}'.laserschwert.io",
    "proxied": false,
    "type": "A",
    "comment": "group '${GROUP}'",
    "ttl": 3600
  }' > /dev/null
  curl --request POST -s \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{
    "content": "'${PUBLIC_IP}'",
    "name": "*.'${VM_HOST}'.laserschwert.io",
    "proxied": false,
    "type": "A",
    "comment": "group '${GROUP}'",
    "ttl": 3600
  }' > /dev/null

done <<< "${VMS}"
