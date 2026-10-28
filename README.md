# keycloak/ — central IAM for GoTravelNha + Family Hub

Keycloak **26.8.1** (Quarkus) with its own Postgres 16. A single realm, `gotravelnha`, holds every user account. GoTravelNha web, GoTravelNha mobile, Family Hub web, and Family Hub mobile all sign in through it, so one account and one SSO session cover every product.

```
keycloak/
├── docker-compose.yml        # local dev (start-dev, ports 8080/9000, Postgres on 5433)
├── docker-compose.prod.yml   # self-hosted prod behind a TLS proxy
├── Dockerfile                # optimized prod image (kc.sh build baked in)
├── docker/entrypoint.sh      # DATABASE_URL → JDBC URL, then kc.sh
├── render.yaml               # Render Blueprint: Keycloak + Render Postgres
├── .env.example              # copy to .env
├── realm/gotravelnha-realm.json   # realm-as-code, imported on first boot
├── themes/gotravelnha/       # brand theme: login/auth pages + account console (see themes/README.md)
├── scripts/
│   ├── kcadm.sh              # kcadm inside the container, already logged in
│   ├── create-user.sh        # verified user + password, optional --admin
│   ├── setup-google-idp.sh   # "Sign in with Google" (idempotent)
│   └── export-realm.sh       # dump live realm config to ./export/
└── docs/
    ├── integration.md        # how each app connects
    └── render.md             # Render deployment walkthrough
```

## Run locally

```bash
cp .env.example .env          # then replace every change-me-* (openssl rand -hex 32)
docker compose up -d
docker compose ps             # keycloak should show (healthy) after ~30s
```

| What | URL |
| --- | --- |
| Admin console | http://localhost:8080/admin (user/password: `KC_BOOTSTRAP_ADMIN_*`) |
| Realm discovery | http://localhost:8080/realms/gotravelnha/.well-known/openid-configuration |
| Account self-service | http://localhost:8080/realms/gotravelnha/account |
| Health / metrics | http://localhost:9000/health/ready, http://localhost:9000/metrics |

```bash
./scripts/create-user.sh me@example.com 'S3cret-pass!' --admin
GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=... ./scripts/setup-google-idp.sh
./scripts/kcadm.sh get realms/gotravelnha/clients --fields clientId,redirectUris
```

Reset everything: `docker compose down -v` (this deletes the Keycloak database).

## What the realm configures

**Login:** self-registration on (signs the user straight in: no email verification, no default required actions), email is the username, password reset, remember-me. Passwords need at least 8 characters, cannot equal the email or username, and cannot repeat the last 3. Brute-force lockout starts after 5 failures and backs off up to 15 minutes. UI languages are `en`, `vi`, and `zh-CN`, the same three the apps support.

**Tokens:** access tokens last 5 minutes. A browser SSO session ends after 30 minutes idle or 10 hours total (14 days idle and 30 days total with remember-me). Mobile offline sessions (`offline_access` scope) end after 30 days idle or 60 days total. Refresh tokens rotate and each can be used once.

**Clients:**

| clientId | Type | Used by | Redirect URI | Access-token `aud` |
| --- | --- | --- | --- | --- |
| `gotravelnha-web` | confidential + PKCE | Nuxt server (`web/`) | `${GTN_WEB_URL}/auth/keycloak` | `gotravelnha-api` |
| `gotravelnha-mobile` | public + PKCE | Flutter (`mobile/`) | `com.gotravelnha.app:/oauth2redirect` | `gotravelnha-api` |
| `familyhub-web` | public + PKCE | React SPA (`familyhubapp/apps/web`) | `${FH_WEB_URL}/auth/callback` | `familyhub-api` |
| `familyhub-mobile` | public + PKCE | Expo (`familyhubapp/apps/mobile`) | `com.familyhub.mobile:/oauth2redirect`, `familyhub://auth/callback` | `familyhub-api` |
| `gotravelnha-api` | resource server | audience only, no login | — | — |
| `familyhub-api` | resource server | audience only, no login | — | — |
| `iam-admin` | service account | backends and scripts that manage users | — | — |

Every login client requires PKCE S256. Implicit flow and the password grant are turned off. `localhost` redirect URIs are always included so dev keeps working against a prod-configured realm. Remove them once you are live if you prefer.

**Roles:** every new account gets the realm role `user`. The `admin` role (or membership in the `gotravelnha-admins` group) corresponds to `User.role = ADMIN` on the web app. Family Hub's `parent`/`child` roles are per family, so they stay in the Family Hub database. Keycloak only answers "who is this person"; the Family Hub API still decides what they can do in each family.

**Email:** SMTP defaults to Resend (`smtp.resend.com:465`). Set `SMTP_PASSWORD` to your Resend API key. Until then, verification and reset emails will fail to send.

## Changing configuration

`realm/gotravelnha-realm.json` is imported **only when the realm does not exist yet**. On later boots it is skipped, as are the `${VAR}` placeholders that read from `.env`. After the first boot:

1. Make the change in the admin console, or with `./scripts/kcadm.sh`.
2. Copy the same change into `realm/gotravelnha-realm.json` so a fresh environment matches. `./scripts/export-realm.sh` dumps the live config for diffing.

## Production

Target: `https://auth.gotravelnha.com`, running the image from `Dockerfile`.

- **Self-hosted VM:** `docker compose -f docker-compose.prod.yml up -d --build`, with Caddy or Nginx in front terminating TLS and proxying to `127.0.0.1:8080`. Do **not** expose port 9000 publicly.
- **Render (chosen):** `render.yaml` is a Blueprint that creates the Keycloak web service and a Render-managed Postgres in Singapore. Follow [`docs/render.md`](docs/render.md).
- **Database on Neon (alternative):** create a `keycloak` database and use the **direct (non-pooled)** host: `KC_DB_URL=jdbc:postgresql://<direct-host>/keycloak?sslmode=require`. Keycloak keeps its own connection pool and does not work well behind PgBouncer transaction pooling.
- In prod `.env`, set `GTN_WEB_URL=https://gotravelnha.com` and `FH_WEB_URL=<family hub web origin>` **before the first boot**, so the import writes the right redirect URIs.
- After first login, create a named admin in the `master` realm and delete the bootstrap `admin` user.
- Back up the Keycloak database like any other production database. It holds every password hash.
- Upgrades: change the tag in `Dockerfile` and both compose files, read the release's upgrade notes, back up the database, and redeploy. Keycloak migrates its schema on startup.

## Next steps (not done yet)

The apps are not wired to Keycloak yet. See [`docs/integration.md`](docs/integration.md) for per-app instructions and for migrating existing users (both existing apps store bcrypt hashes).

- Change the Flutter app id from `com.example.gotravelnha_app` to `com.gotravelnha.app`, or change the `gotravelnha-mobile` redirect URI to match whatever id you choose.
- Apple sign-in (required by App Store rules if Google sign-in is offered on iOS): add it as an identity provider.
