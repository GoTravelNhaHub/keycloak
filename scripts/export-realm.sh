#!/usr/bin/env bash
# Export the live gotravelnha realm (config only, no users) to ./export/ for diffing
# against realm/gotravelnha-realm.json. Secrets are masked in the output.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p export
./scripts/kcadm.sh create realms/gotravelnha/partial-export -q exportClients=true -q exportGroupsAndRoles=true -o \
  > "export/gotravelnha-realm.$(date +%Y%m%d-%H%M%S).json"
ls -1t export | head -1
