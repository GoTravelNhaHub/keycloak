#!/bin/bash
# Turns a libpq-style DATABASE_URL (what Render, Heroku, Neon hand out) into Keycloak's
# JDBC URL, then starts Keycloak. Ignored when KC_DB_URL is already set.
#   postgresql://user:pass@host[:port]/db?x=y  ->  jdbc:postgresql://host[:port]/db?x=y
set -euo pipefail

if [[ -n "${DATABASE_URL:-}" && -z "${KC_DB_URL:-}" ]]; then
  rest="${DATABASE_URL#*://}"        # user:pass@host:port/db?x=y
  creds="${rest%%@*}"
  hostpart="${rest#*@}"              # host:port/db?x=y
  export KC_DB_URL="jdbc:postgresql://${hostpart}"
  # Explicit KC_DB_USERNAME / KC_DB_PASSWORD win over the credentials in the URL.
  export KC_DB_USERNAME="${KC_DB_USERNAME:-${creds%%:*}}"
  export KC_DB_PASSWORD="${KC_DB_PASSWORD:-${creds#*:}}"
fi

exec /opt/keycloak/bin/kc.sh "$@"
