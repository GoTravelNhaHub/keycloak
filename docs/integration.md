# Connecting the apps to Keycloak

Issuer (dev): `http://localhost:8080/realms/gotravelnha`
Issuer (prod): `https://auth.gotravelnha.com/realms/gotravelnha`
Discovery: `<issuer>/.well-known/openid-configuration`. JWKS: `<issuer>/protocol/openid-connect/certs`.

Every app uses Authorization Code + PKCE (S256). The user's stable id is the token's `sub` (a UUID). Store it on your local user row (for example a new `keycloakId`/`keycloak_id` column, unique) and look users up by it, not by email.

## 1. GoTravelNha web (Nuxt, `web/`), client `gotravelnha-web`

The Nuxt server is a confidential client. It does the code exchange and keeps tokens out of the browser.

- Library: `nuxt-auth-utils`, which has a built-in Keycloak OAuth provider and a sealed-cookie session that uses the existing `SESSION_PASSWORD`.
- Env:
  ```
  NUXT_OAUTH_KEYCLOAK_SERVER_URL=http://localhost:8080
  NUXT_OAUTH_KEYCLOAK_REALM=gotravelnha
  NUXT_OAUTH_KEYCLOAK_CLIENT_ID=gotravelnha-web
  NUXT_OAUTH_KEYCLOAK_CLIENT_SECRET=<GTN_WEB_CLIENT_SECRET>
  NUXT_OAUTH_KEYCLOAK_REDIRECT_URL=http://localhost:3000/auth/keycloak
  ```
- Route `server/routes/auth/keycloak.get.ts` → `defineOAuthKeycloakEventHandler({ onSuccess })`. In `onSuccess`, upsert `User` by `sub` (set `role = ADMIN` when `realm_access.roles` contains `admin`), then call `setUserSession`.
- Logout: clear the session, then redirect to `<issuer>/protocol/openid-connect/logout?client_id=gotravelnha-web&post_logout_redirect_uri=http://localhost:3000/`.
- **Mobile calls the same `/api`.** For requests that carry `Authorization: Bearer`, verify the JWT with `jose` (`createRemoteJWKSet(<JWKS>)`, `jwtVerify(token, jwks, { issuer, audience: 'gotravelnha-api' })`). Put that check in a server util and apply it to `/api/user/**` and `/api/admin/**`. Today those routes are not consistently authenticated (see `web/CLAUDE.md`).
- `register.vue`, `forgot-password.vue`, and `reset-password.vue` become redirects to Keycloak: registration via `<issuer>/protocol/openid-connect/registrations?...`, password reset from the login page. Move the existing Google OAuth (`server/api/auth/google/`) into Keycloak with `scripts/setup-google-idp.sh`.

## 2. GoTravelNha mobile (Flutter, `mobile/`), client `gotravelnha-mobile`

- Packages: `flutter_appauth` (system browser + PKCE) and `flutter_secure_storage` for the refresh token.
- `authorizeAndExchangeCode(AuthorizationTokenRequest('gotravelnha-mobile', 'com.gotravelnha.app:/oauth2redirect', issuer: ISSUER, scopes: ['openid','profile','email','offline_access']))`.
- Android `build.gradle.kts`: `manifestPlaceholders["appAuthRedirectScheme"] = "com.gotravelnha.app"`. iOS: add `com.gotravelnha.app` to `CFBundleURLSchemes`.
- Pass `ISSUER` and the API base URL with `--dart-define`. Attach the access token with a dio interceptor that refreshes on 401.
- Android emulators reach the host at `10.0.2.2`, but the token `iss` must match `KC_HOSTNAME`. For device testing, set `KC_HOSTNAME` to your LAN IP (for example `http://192.168.1.10:8080`) and use the same value in the app.

## 3. Family Hub web (React SPA), client `familyhub-web`

- Library: `oidc-client-ts` + `react-oidc-context`. Config: `authority=<issuer>`, `client_id=familyhub-web`, `redirect_uri=${origin}/auth/callback`, `scope='openid profile email'`.
- Add a `/auth/callback` route to React Router.
- Send `Authorization: Bearer <access_token>` to `VITE_API_URL`, the same way the current JWT is sent.
- New env vars: `VITE_OIDC_ISSUER`, `VITE_OIDC_CLIENT_ID`.

## 4. Family Hub mobile (Expo), client `familyhub-mobile`

- `expo-auth-session` + `expo-secure-store`. Set `"scheme": "familyhub"` in `app.json`.
- `useAuthRequest({ clientId: 'familyhub-mobile', redirectUri: makeRedirectUri({ scheme: 'familyhub', path: 'auth/callback' }), scopes: ['openid','profile','email','offline_access'], usePKCE: true }, useAutoDiscovery(ISSUER))`.
- Expo Go uses `exp://<ip>:8081/--/auth/callback` redirects. For dev only, add that exact URI to the client (`./scripts/kcadm.sh update clients/<id> -r gotravelnha -s 'redirectUris=[...]'`). Do not add a wildcard in prod.

## 5. Family Hub API (NestJS), resource server `familyhub-api`

Replace the HS256 secret in `apps/api/src/auth/jwt.strategy.ts` with Keycloak's JWKS:

```ts
import { passportJwtSecret } from "jwks-rsa";

super({
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  secretOrKeyProvider: passportJwtSecret({
    jwksUri: `${process.env.OIDC_ISSUER}/protocol/openid-connect/certs`,
    cache: true,
    rateLimit: true,
  }),
  issuer: process.env.OIDC_ISSUER,
  audience: "familyhub-api",
  algorithms: ["RS256"],
});
```

In `validate()`, find the `User` by `keycloakId = payload.sub`. If none exists, create one on first sight from `payload.email`. `AuthContext`, `resolveFamilyScope`, and `requireParent` stay unchanged, because memberships still come from the database. The `register`, `login`, `refresh`, and password-reset endpoints, plus the `RefreshToken`/`PasswordResetToken` tables, can be removed once every client has switched.

## Migrating existing users

Both apps store bcrypt hashes (`web` cost 10, Family Hub cost 12). Keycloak 26 cannot verify bcrypt out of the box. Pick one:

1. **Force reset (simplest).** Import users without passwords using the `iam-admin` service account (`POST /admin/realms/gotravelnha/users`, `emailVerified: true`, `requiredActions: ["UPDATE_PASSWORD"]`), then send `PUT /users/{id}/execute-actions-email`. Google users only need to sign in with Google again; the account links by email.
2. **Keep passwords.** Install a bcrypt password-hash provider jar into `/opt/keycloak/providers` (add `COPY` to the Dockerfile before `kc.sh build`). Then import each hash as a credential with `algorithm: "bcrypt"`. Keycloak re-hashes to its default algorithm on the next login. Check the provider's compatibility with 26.8 before relying on it.
3. **Lazy migration.** Write a User Storage SPI that checks passwords against the old database on first login and then copies the user over. This is the most work. Use it only if a forced reset is unacceptable.

Users who have an account in both GoTravelNha and Family Hub under the same email become **one** Keycloak user. Write each app's `keycloakId` back to its own user table during the import.
