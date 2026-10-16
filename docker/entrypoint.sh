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

# Fail fast with a readable message instead of a Keycloak stack trace.
if [[ "${1:-}" == "start" ]]; then
  if [[ -z "${KC_DB_URL:-}" && -z "${KC_DB_URL_HOST:-}" ]]; then
    echo "entrypoint: no database configured. Set DATABASE_URL to the Postgres Internal Database URL" \
         "(postgresql://user:pass@host/db), or KC_DB_URL / KC_DB_URL_HOST." >&2
    exit 1
  fi
  if [[ -z "${KC_HOSTNAME:-}" ]]; then
    echo "entrypoint: WARNING KC_HOSTNAME is not set. Set it to the public URL, e.g." \
         "https://auth.gotravelnha.com, so tokens get a fixed issuer." >&2
  fi
fi

exec /opt/keycloak/bin/kc.sh "$@"
