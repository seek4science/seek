# Code review — `openid-api-2733`

OpenID Connect access tokens for the API. Reviewed 2026-09-09 against `main`
(head: `ee6f5006ec`).

Findings are ordered most severe first. (1) and (2) look like blockers.

## 1. Blank audience list accepts any token the issuer signed, for anybody

`lib/seek/oidc/access_token_verifier.rb:99-101`, `lib/seek/config.rb:437`

`omniauth_oidc_api_audiences` defaults to `''`, so `audience_accepted?` returns
`true` unconditionally. Nothing checks the token type either — `typ` / `at+jwt`
is ignored, and `azp` is only consulted when a list exists.

On a shared IdP (Google, or an institutional Keycloak realm serving several
clients) any access *or* ID token minted for any unrelated relying party the
user has authorised becomes a full SEEK API credential for that user. The
operator of any such client can act as every linked SEEK user.

The admin help text warns about this, but a security-critical toggle should not
be safe only if the admin reads the paragraph. Either refuse to enable
`omniauth_oidc_api_enabled` while the list is blank, or default the list to
`omniauth_oidc_client_id`.

## 2. The discovery request has no timeouts, so a hung IdP takes down the instance

`lib/seek/oidc/discovery.rb:89`

The bounded `http_client` (2 s open / 5 s read, line 102) is used only for the
JWKS *body* fetch. `jwks_uri` goes through
`OpenIDConnect::Discovery::Provider::Config.discover!` → `SWD::Resource` →
`SWD.http_client`, which is a bare `Faraday.new` with no `open_timeout` or
`timeout`; nothing in the repo sets `SWD.http_config` or
`OpenIDConnect.http_config`.

If the provider accepts the TCP connection to
`/.well-known/openid-configuration` and never responds, the request thread
blocks forever. Because no exception is raised, `reaching_provider` never writes
the unavailability marker, so every subsequent request carrying a JWT-shaped
bearer token blocks as well — the Puma pool is exhausted and the whole instance
goes down, not just OIDC auth.

`docs/OIDC_API_CREDENTIALS.md:277` currently claims the opposite ("A hung
provider would otherwise tie up Puma threads").

Fix: set `SWD.http_config`, or fetch the discovery document with the same
bounded Faraday connection.

## 3. One unknown key type poisons the whole key set for 12 hours

`lib/seek/oidc/discovery.rb:95`

`JWT::JWK::Set.new(JSON.parse(json))` builds the set in one go, and
`JWT::JWK.create_from` raises `JWT::JWKError, "Key type X not supported"` for
any entry it cannot map — jwt 3.2 supports only `RSA`, `EC` and `oct`. Confirmed
by running it: a JWKS holding a good RSA key plus one `kty: "OKP"` (Ed25519)
entry raises rather than yielding the usable key. Providers do publish mixed
sets (Keycloak / Authentik / Hydra with an EdDSA key provider, or some future
`kty`).

The failure is sticky and misdiagnosed: `parse` runs inside
`reaching_provider`, so the `JWKError` is logged as "OpenID Connect provider …
unavailable", the *valid* JSON stays in `Rails.cache` for 12 h, and every retry
re-raises. OIDC API auth is dead for 12 h behind a log line that points at the
provider's availability.

Fix: build the set key by key with a per-key `rescue JWT::JWKError`, or
pre-filter on `kty`.

## 4. The unavailability marker rejects tokens that could be verified offline

`lib/seek/oidc/discovery.rb:33`

The `raise Error if provider_unavailable?` guard sits ahead of both `@key_set`
and the 12 h cached JWKS entry, so it refuses tokens it could verify without
touching the network.

An unauthenticated caller sending a token with an invented `kid` trips the
once-per-5-minutes `refresh!`. If the provider answers 502 (or times out) for
that single request, the marker is written and for the next 60 s *every*
legitimate OIDC API request is rejected despite a valid cached key set. That is
repeatable indefinitely, and it also turns any brief provider blip into a minute
of API downtime.

Fix: guard the fetch, not the use of an already-cached set.

## 5. A genuine token for an unlinked subject still pays the API-token throttle

`lib/authenticated_system.rb:151`

The comment says OIDC is tried first "so that a genuine token does not pay that
method's throttling delay", but that only holds when the token resolves to a
user. A correctly signed token whose `sub` has no `Identity` — the documented
state for a user who has not linked yet — or any JWT over `MAX_TOKEN_BYTES`
returns `nil` and falls through to `user_from_api_token`, which does `sleep 2`
in production.

So the ordinary "you need to link your account first" case costs 2 s of a Puma
thread per request, and an unauthenticated caller can park threads 2 s at a time
with JWT-shaped garbage.

Fix: short-circuit when `plausible_jwt?` matched, or skip the throttle for
credentials already rejected upstream.

## 6. `MAX_JWKS_BYTES` is checked after the body is fully buffered

`lib/seek/oidc/discovery.rb:78`

`body = http_client.get(uri).body.to_s` reads the whole response into memory
before `body.bytesize > MAX_JWKS_BYTES` is evaluated, so the 128 KB limit bounds
nothing. A compromised or misbehaving JWKS endpoint streaming gigabytes is
bounded only by the 5 s read timeout.

Fix: enforce it with Faraday's `on_data` streaming callback, or treat the check
as documentation of intent rather than as a limit.

## 7. The key-rotation test never exercises rotation

`test/unit/oidc/access_token_verifier_test.rb:135`

In `'picks up a rotated provider key'`, `stub_oidc_key_set` replaces the `/jwks`
stub *before* the first fetch, and the cache was cleared in `setup`. The very
first lookup therefore already returns the rotated key and the `invalidate:
true` refetch path is never entered — a regression in `refresh!` or
`refresh_allowed?` would leave this test green.

Fix: prime the cache with the old key set first (verify a token signed by the
original key), then re-stub, and assert
`assert_requested :get, "#{OIDC_ISSUER}/jwks", times: 2`.

## Checked and found correct

- The ruby-jwt option set is right for jwt 3.2: `verify_iss` keys off
  `options[:iss]`, `exp_leeway` / `nbf_leeway` are honoured separately, and
  `verify_algo` runs before `set_key`, so the algorithm allowlist really does
  prevent key lookup for `alg: none` and HS256 confusion.
- `JWT::JWK::Set.new` accepts a `Set`, so the double-wrap in `KeyFinder` is
  harmless.
- `refresh_allowed?`'s `unless_exist:` write does reach Redis `SET NX` through
  `Seek::Caching::RedisWithFileOverflowStore`.
- The `OIDC` inflection follows the existing `lib/seek/isa` → `Seek::ISA`
  precedent.
- `jwt ~> 3.2` only collides with `oauth2`, which touches `JWT.encode` in the
  unused assertion strategy.
