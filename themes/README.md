# Keycloak themes

`gotravelnha/` is the brand theme, set as `loginTheme` and `accountTheme` in `realm/gotravelnha-realm.json`.
In dev these files are mounted read-only into `/opt/keycloak/themes`, and `start-dev` turns caching off,
so a browser refresh shows CSS, template, and message edits. The prod `Dockerfile` copies them into the image.

| Part | Extends | What it changes |
| --- | --- | --- |
| `login/` | `keycloak.v2` | Every auth page: sign in, register, forgot/reset password, verify email, update profile, OTP, errors |
| `account/` | `keycloak.v3` | Account console (React): logo, colours, white header, shorter menu (`resources/content.json`) |

Changing your password from the account console opens the login theme's `login-update-password` page.

## Where the look comes from

- Colours, radii, and form/button styles copy `web/assets/css/tailwind.css` (`.form-input`, `.btn-primary`, ...).
- The split layout (photo panel and form) copies `web/components/site/AuthShell.vue`.
- The logo uses the same paths as `web/components/Logo.vue` and `web/public/favicon.svg`.
- Copy comes from `web/locales/{en,vi,zh}/auth.ts`, in `login/messages/messages_{en,vi,zh_Hans}.properties`.
  Keycloak runs every message through Java MessageFormat, so write an apostrophe as `''`.
- The photos in `login/resources/img/` are the Unsplash images the web auth pages use, stored locally.

## Editing

- **Per-page copy:** the subtitle, headline, subline and points use keys like `gtnHeadline.<pageId>`, falling back to
  `.default`. The page id is the template name without `.ftl` (`login`, `register`, `login-reset-password`, ...).
  `gtnPoints.*` is a `|`-separated list; leave it empty to show no bullets.
- **Photo per page:** see `gtnImage()` in `login/template.ftl`.
- **Upgrading Keycloak:** `login/template.ftl` and `login/social-providers.ftl` are copies of the `keycloak.v2`
  files with the layout changed. Diff them against the new version's originals and carry over any new
  scripts or sections. The account theme only adds CSS, so check it visually.
- Dark mode is off in both parts (`darkMode=false`), matching the light-only website.
