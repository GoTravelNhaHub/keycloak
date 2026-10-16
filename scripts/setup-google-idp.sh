#!/usr/bin/env bash
# Add "Sign in with Google" to the gotravelnha realm (idempotent: creates or updates).
#   GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=... ./scripts/setup-google-idp.sh
# In Google Cloud Console, add this Authorized redirect URI to the OAuth client:
#   ${KC_HOSTNAME}/realms/gotravelnha/broker/google/endpoint
set -euo pipefail
cd "$(dirname "$0")"
: "${GOOGLE_CLIENT_ID:?set GOOGLE_CLIENT_ID}"
: "${GOOGLE_CLIENT_SECRET:?set GOOGLE_CLIENT_SECRET}"

ARGS=(-s alias=google -s providerId=google -s enabled=true -s displayName=Google
  -s trustEmail=true -s firstBrokerLoginFlowAlias="first broker login"
  -s "config.clientId=$GOOGLE_CLIENT_ID" -s "config.clientSecret=$GOOGLE_CLIENT_SECRET"
  -s config.defaultScope="openid profile email" -s config.syncMode=IMPORT)

if ./kcadm.sh get identity-provider/instances/google -r gotravelnha >/dev/null 2>&1; then
  ./kcadm.sh update identity-provider/instances/google -r gotravelnha "${ARGS[@]}"
  echo "Updated Google identity provider."
else
  ./kcadm.sh create identity-provider/instances -r gotravelnha "${ARGS[@]}"
  echo "Created Google identity provider."
fi
