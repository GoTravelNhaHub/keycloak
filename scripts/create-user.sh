#!/usr/bin/env bash
# Create a verified user with a password (dev/testing). Add --admin to grant the admin realm role.
#   ./scripts/create-user.sh you@example.com 'S3cret-pass!' [--admin]
set -euo pipefail
cd "$(dirname "$0")"
EMAIL="${1:?email}"; PASSWORD="${2:?password}"

./kcadm.sh create users -r gotravelnha -s "username=$EMAIL" -s "email=$EMAIL" \
  -s emailVerified=true -s enabled=true
./kcadm.sh set-password -r gotravelnha --username "$EMAIL" --new-password "$PASSWORD"
if [[ "${3:-}" == "--admin" ]]; then
  ./kcadm.sh add-roles -r gotravelnha --uusername "$EMAIL" --rolename admin
fi
echo "Created $EMAIL"
