#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=${SCRIPT%/*}
PROJECT_DIR=$(readlink -f "${SCRIPT_DIR}/..")

cd "$SCRIPT_DIR"

set -a
source "$PROJECT_DIR/.env"
set +a

printf "\nDelete DNS records for group '${GROUP}'\n"
ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=laserschwert.io" \
               -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
               -H "Content-Type: application/json" \
          | yq -oy '.result[0].id')

DNS=$(curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?comment=group+${GROUP}" \
           -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
           -H "Content-Type: application/json" \
        | yq -oy '.result[].id')

for dns_id in $DNS; do
  curl -X DELETE -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${dns_id}" \
       -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" > /dev/null
done
