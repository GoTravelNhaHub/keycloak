#!/usr/bin/env bash
# Point the live `gotravelnha-web` client at the split deployment (idempotent):
#   api.gotravelnha.com   runs the login (redirect URI /auth/callback)
#   www / admin           are where users land after logout
# realm/gotravelnha-realm.json has the same values, but it is only read on the realm's first import.
#
#   KC_URL=https://auth.gotravelnha.com KC_ADMIN_USER=admin KC_ADMIN_PASSWORD=... ./scripts/configure-subdomains.sh
#
# Optional: GTN_API_URL, GTN_WEB_URL, GTN_ADMIN_URL (defaults below), KEEP_LOCALHOST=0 to drop localhost URIs.
set -euo pipefail

KC_URL="${KC_URL:-https://auth.gotravelnha.com}"
: "${KC_ADMIN_USER:?set KC_ADMIN_USER (master realm admin)}"
: "${KC_ADMIN_PASSWORD:?set KC_ADMIN_PASSWORD}"
API="${GTN_API_URL:-https://api.gotravelnha.com}"
WEB="${GTN_WEB_URL:-https://www.gotravelnha.com}"
ADMIN="${GTN_ADMIN_URL:-https://admin.gotravelnha.com}"
KEEP_LOCALHOST="${KEEP_LOCALHOST:-1}"

TOKEN=$(curl -fsS "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=admin-cli \
  --data-urlencode "username=$KC_ADMIN_USER" --data-urlencode "password=$KC_ADMIN_PASSWORD" |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

BASE="$KC_URL/admin/realms/gotravelnha"
CLIENT_JSON=$(curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE/clients?clientId=gotravelnha-web")

UPDATED=$(API="$API" WEB="$WEB" ADMIN="$ADMIN" KEEP_LOCALHOST="$KEEP_LOCALHOST" python3 -c '
import json, os, sys
clients = json.loads(sys.argv[1])
if not clients:
    sys.exit("gotravelnha-web client not found")
c = clients[0]
api, web, admin = os.environ["API"], os.environ["WEB"], os.environ["ADMIN"]
local = os.environ["KEEP_LOCALHOST"] == "1"
apex = web.replace("://www.", "://")
c["name"] = "GoTravelNha (api.gotravelnha.com)"
c["rootUrl"] = web
c["baseUrl"] = "/"
c["redirectUris"] = [f"{api}/auth/callback"] + (["http://localhost:3002/auth/callback"] if local else [])
c["webOrigins"] = [api] + (["http://localhost:3002"] if local else [])
logout = [f"{web}/*", f"{apex}/*", f"{admin}/*"] + (["http://localhost:3000/*", "http://localhost:3001/*"] if local else [])
c.setdefault("attributes", {})["post.logout.redirect.uris"] = "##".join(dict.fromkeys(logout))
print(json.dumps(c))
' "$CLIENT_JSON")

ID=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["id"])' "$UPDATED")
curl -fsS -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  --data "$UPDATED" "$BASE/clients/$ID" >/dev/null

echo "gotravelnha-web updated:"
python3 -c '
import json, sys
c = json.loads(sys.argv[1])
print("  redirectUris:            ", c["redirectUris"])
print("  post.logout.redirect.uris:", c["attributes"]["post.logout.redirect.uris"].split("##"))
' "$UPDATED"
