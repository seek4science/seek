# OpenID Connect (OIDC) in FAIRDOM-SEEK

SEEK supports OpenID Connect via OmniAuth. Configure it under **Admin → Server settings → OmniAuth**.

## Enable OIDC

1. Set **Site base host** (Admin → Server settings) to the public URL of this SEEK instance (e.g. `https://seek.example.org` or `http://localhost:3000`).
2. Enable **OmniAuth** and **OpenID Connect**.
3. Set **OIDC URL** (issuer), **Client ID**, and **Secret** from your identity provider.
4. Optionally set **OIDC Scopes** (default `openid email profile`). Add any extra scope required for group claims (e.g. `entitlement`).
5. Register this **Redirect URI** at the identity provider (shown in the Admin OIDC panel):

   `{site_base_host}/auth/oidc/callback`

   Example: `http://localhost:3000/auth/oidc/callback`

SEEK builds the redirect URI from `site_base_host`. There is no separate redirect-URI setting.

6. Restart SEEK after changing OmniAuth provider settings so the OmniAuth middleware reloads.

### New users

With **Create user accounts** enabled, a successful first OIDC login creates a SEEK user and sends them through the normal profile registration flow. Group → Project sync (below) runs once a Person profile exists.

## Map OIDC groups to Projects

Optional feature (default **off**): on login, values from a configured OIDC claim become SEEK Projects, and the user is added as a member.

### Enable

1. Enable **Map OIDC groups to Projects**.
2. Set **Groups claim path** (dot-notation into userinfo / ID token claims), for example:
   - `entitlement` — SRAM / many eduGAIN-style entitlements
   - `groups` — plain groups claim
   - `realm_access.roles` — Keycloak realm roles
3. Request any scope needed so the claim appears (see **OIDC Scopes**).
4. Optionally choose a **default Institution** for new memberships; otherwise SEEK uses the person's first institution (or the first Institution in the database).

### Behaviour (v1)

For each group value in the claim:

1. Derive a Project title: last segment after `:`, `/`, `#`, or `@`; otherwise the full string  
   (e.g. `urn:mace:example.org:group:my-project` → `my-project`).
2. If no Project with that title exists → **create** it and make the user a **project administrator**.
3. If the Project exists but has **no** administrators → make the user a **project administrator**.
4. Otherwise → add the user as a normal **member** (if not already).

Membership is **additive only**: leaving a group at the identity provider does **not** remove SEEK membership or demote administrators.

### Settings reference

| Setting | Purpose | Default |
|---------|---------|---------|
| `omniauth_oidc_scope` | Space-separated OIDC scopes | `openid email profile` |
| `omniauth_oidc_groups_enabled` | Enable group → Project sync | `false` |
| `omniauth_oidc_groups_claim` | Claim path (dot-notation) | `entitlement` |
| `omniauth_oidc_groups_institution_id` | Institution for new memberships | (person's / first available) |

## Docker / environment examples

Stock `docker-compose.yml` does **not** turn OIDC on. For local experiments, copy `.env.example` to `.env` and use `docker-compose.override.yml.example` as a template for optional bind mounts (ENV defaults, default Institution, optional Person auto-create). Prefer Admin UI settings for production; ENV defaults only apply until settings are persisted in the database.

## Implementation notes

- Sync service: `Seek::Omniauth::OidcGroupProjectSync`
- Hook: `SessionsController` after a successful OIDC login when the user has a Person
- OmniAuth login uses a same-origin HTML bounce plus remember-me cookie so the session is not lost after the IdP cross-site return
