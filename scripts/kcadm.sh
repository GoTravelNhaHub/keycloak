#!/usr/bin/env bash
# Run kcadm.sh inside the keycloak container, already logged in as the bootstrap admin.
#   ./scripts/kcadm.sh get realms/gotravelnha/clients -q clientId=gotravelnha-web --fields id,redirectUris
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
CONTAINER="${KC_CONTAINER:-keycloak}"

docker exec "$CONTAINER" /opt/keycloak/bin/kcadm.sh config credentials \
  --config /tmp/kcadm.config --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1
docker exec -i "$CONTAINER" /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
