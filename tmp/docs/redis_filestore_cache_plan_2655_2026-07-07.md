# Redis + FileStore Hybrid Caching — Implementation Plan

Issue: [#2655](https://github.com/seek4science/seek/issues/2655) — "Update SEEK to use Redis for caching"
Branch: `redis-cache-store-2655`

**Commit convention:** every commit for this work references the issue (e.g. `refs #2655` in the
message body) so it shows up on the issue's timeline — not just `#2655` in the PR description.

## Goal

Replace the filesystem-based production cache (`config.cache_store = :file_store`) with Redis,
while keeping a configurable maximum item size above which entries continue to be stored on and
retrieved from the filesystem, and logging whenever an item is too large for Redis and overflows
to disk.

## Issue requirements (verbatim scope)

1. Replace the filesystem cache with Redis (already deployed for sessions).
2. A configurable maximum size — items above it are stored/retrieved via the filesystem instead.
3. An exception-notification email when an item is too large to cache in Redis.
4. Investigate Solid Cache first, as an alternative, before implementing.

Requirement 3 is deliberately *not* built as written — see the decision below.

## Decision: Redis + FileStore overflow, not Solid Cache

Investigated per the issue's instruction before starting implementation. Summary of the decision:

- Redis is already deployed and trusted in this stack (sessions, Action Cable) and the `redis`
  gem is already in the `Gemfile` — adopting it for caching is close to zero new dependency cost.
- Solid Cache would add a new gem, a migration, and a dedicated database role, and would push
  cache write/read traffic through MySQL (query overhead, connection pool pressure, binlog
  replication churn) for no benefit `seek`/`seek_workers` don't already get from the filesystem.
- `seek` and `seek_workers` already mount the same `seek-cache` Docker volume
  (`docker-compose.yml`, the `seek_base` anchor), so the filesystem cache is **already a shared
  cache** between the web process and the `delayed_job` workers on a given host — the usual
  objection to filesystem caches (node-local, not shared) is largely moot here.
- The issue's own design — "keep large items on the filesystem" — is exactly what SEEK already
  does today for large items, just without a Redis tier in front of it. Solid Cache doesn't offer
  anything extra for that half of the problem.
- Conclusion: build a single cache store that writes to Redis by default and overflows to the
  existing filesystem cache above a configurable size, rather than introducing Solid Cache.

## Decision: log oversized writes, don't email on every one

The issue asks for a notification email whenever an item is too large to cache in Redis. Overflow
to disk is the expected, designed-for behaviour for the large-item call sites already identified
(spreadsheet XML/CSV, notebook HTML, RightField output, ontology hierarchies) — those will
overflow routinely, every time their content changes, not exceptionally. An email per occurrence
(even deduped) would either be constant background noise or get filtered out and ignored, which
defeats the purpose of an exception notification. Instead: log every overflow (`Rails.logger`,
searchable, no inbox involved) and keep the admin-email pipeline for things that are genuinely
unexpected, not for routine operation of the feature this issue is building.

## Architecture

One cache store, `Seek::Caching::RedisWithFileOverflowStore`, replaces `Rails.cache`. It wraps a
`RedisCacheStore` and a `FileStore` and picks between them per key based on serialized entry size:

- **Write**: serialize the entry, measure its byte size.
  - `size <= Seek::Config.cache_max_redis_item_size` → write to Redis, delete any stale copy on
    disk under the same key.
  - `size > Seek::Config.cache_max_redis_item_size` → write to disk, delete any stale copy in
    Redis under the same key, and log the overflow.
- **Read**: check Redis first (cheap, covers the large majority of keys); on a miss, check the
  filesystem store before reporting a true miss.
- **Delete / delete_matched**: delegate to both backends, since a key's location isn't known
  without checking.

This keeps `Rails.cache.fetch(key) { ... }` working unmodified at every one of SEEK's ~45 call
sites — no call site needs to know or care which backend it lands on.

---

## Step 1 — Redis cache infrastructure

Reuse the existing `redis_store` service rather than standing up a second Redis — SEEK already
requires a single reachable Redis instance in every environment, including local (non-Docker) dev:
`config/initializers/session_store.rb` is not environment-gated, so `rails server` run directly on
a developer's machine already needs a local Redis on `localhost:6379` (`REDIS_URL` default) for
sessions to work at all. Adding a second dedicated instance would mean two Redis processes to run
locally, and a new container/volume/health-check in `docker-compose.yml`, for a project at SEEK's
scale — not worth the operational overhead.

**Correction from the original draft of this step:** it assumed `session_store.rb` and
`cable.yml` already separate traffic by logical Redis *db* (0 vs 1). Reading the `redis-store` gem
source (`Redis::Store::Factory.extract_host_options_from_uri`) shows that's not what's happening —
a URL's third path segment (`.../0/session`) is parsed as a **key namespace**, not a second db
number, so sessions actually live in db 0 with keys prefixed `session:...`. `cable.yml`'s
`ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }` only reaches its db-1 fallback when
`REDIS_URL` is completely unset — in `docker-compose.yml`, where `REDIS_URL` is always
`redis://redis_store:6379/0`, Action Cable also resolves to db 0 (moot in practice since cable has
no channels defined anywhere in the app — see below). There's no real db-per-purpose separation
today, just db 0 with one namespace applied ad hoc. `ActiveSupport::Cache::RedisCacheStore`
supports the identical idiom as a first-class constructor option ("Provide one if the Redis cache
server is shared with other apps: `namespace: 'myapp-cache'`" —
`redis_cache_store.rb:132-133`), so the simplest, most consistent fix is to follow the pattern
that's already there rather than invent a db-swapping scheme:

- [x] Reuse `REDIS_URL` as-is for the cache store (same db 0, no new env var, no URL-derivation
      helper needed) and pass `namespace: 'cache'` when constructing the `RedisCacheStore` in
      Step 5 — mirroring how sessions already separate themselves with a namespace, just via a
      constructor option instead of the `redis-store` URL-suffix trick.
- [x] Set `maxmemory` and `maxmemory-policy allkeys-lru` on the existing `redis_store` service in
      `docker-compose.yml` (`512mb`, `allkeys-lru`) — no new service needed.
- [x] Document the shared-instance tradeoff explicitly: `maxmemory-policy` applies
      instance-wide, not per-namespace, so under memory pressure Redis can in principle evict
      session keys, not just cache keys. In practice this is low-risk at SEEK's scale — session
      keys are actively touched (refreshed) while a user is logged in, so LRU naturally
      deprioritises evicting them ahead of cold cache entries — but size `maxmemory` with
      comfortable headroom above the expected session footprint, and monitor `evicted_keys`
      post-launch rather than treating the headroom as a one-time decision.
- [x] No CI task for this step — there's no derivation logic left to unit test (the db-swap helper
      that would have needed one is no longer necessary); the `namespace: 'cache'` wiring gets
      exercised for real by Step 3's store tests and Step 5's config-wiring test against the CI
      Redis service (`.github/workflows/tests.yml` already runs `redis:8.6-alpine` on
      `localhost:6379`).

## Step 2 — Configurable size threshold

- [x] Add `cache_max_redis_item_size` to `lib/seek/config_setting_attributes.yml`
      (`convert: :to_i`) — following the pattern of the existing `max_cachable_size` /
      `hard_max_cachable_size` remote-file-cache settings rather than `max_extractable_spreadsheet_size`:
      those two are the closer precedent since they're already byte-valued cache-size thresholds
      with the same `convert: :to_i` numeric-input treatment, whereas
      `max_extractable_spreadsheet_size` stores MB and needs a `* 1024 * 1024` conversion at every
      call site — bytes avoids that indirection for a threshold that's inherently a byte comparison
      against a serialized entry's `bytesize`.
- [x] Set a default in `config/initializers/seek_configuration.rb`:
      `Seek::Config.default :cache_max_redis_item_size, 1 * 1024 * 1024` (1MB), alongside the
      `max_cachable_size` / `hard_max_cachable_size` defaults.
- [x] Exposed in the admin settings UI (`app/views/admin/settings.html.erb`, `admin_controller.rb
      #update_settings`) as a standalone field — not nested inside the existing
      `block_file_uploads`/`cache_remote_files` toggle blocks, since those gate *remote file*
      downloading/caching, an unrelated feature to the internal `Rails.cache` threshold this
      setting controls.
- [x] **CI:** unit test (`test/unit/config_test.rb`, `cache_max_redis_item_size default and
      persistence`) asserting the 1MB default and that the value persists and coerces to `Integer`
      via `with_config_value`.
- [x] **CI:** functional tests on `AdminController` (`test/functional/admin_controller_test.rb`) —
      one confirming the field renders in the settings form (`assert_select`), one confirming
      `update_settings` persists a posted value to `Seek::Config.cache_max_redis_item_size`.

## Step 3 — `RedisWithFileOverflowStore`

- [x] Created `lib/seek/caching/redis_with_file_overflow_store.rb`,
      `Seek::Caching::RedisWithFileOverflowStore < ActiveSupport::Cache::Store`, constructed with
      `redis_store:`, `file_store:`, and `max_redis_item_size:`.
- [x] Implemented `write_entry`, `read_entry`, `delete_entry` per the architecture above (serialize
      once via this store's own coder to measure `bytesize` — since neither child store customizes
      its coder, this measurement is byte-exact, not approximate — route, and clean up the
      non-chosen backend first so a crash mid-write leaves a safe miss rather than a stale hit on
      the wrong backend). Each read/write/delete calls `normalize_key` on the *target child store*
      (via `send`, since it's private) rather than relying on this store's own key normalization —
      necessary because `FileStore` overrides `normalize_key` to turn the logical key into a
      filesystem path, while `RedisCacheStore` uses it to apply a namespace; delegating per-child
      keeps each backend's key format identical to using that store directly, which is what makes
      old on-disk `tmp/cache` files and the Redis `namespace: 'cache'` option both keep working.
- [x] Implemented `delete_matched` delegating to both backends — with one correction found while
      building it: `RedisCacheStore#delete_matched` only accepts a Redis glob **String** and raises
      `ArgumentError` on anything else, but SEEK has two existing call sites with incompatible
      matcher types — `app/models/content_blob.rb:321` passes a glob **String**
      (`"st-match-#{id}*"`), `lib/seek/stats/dashboard_stats.rb:76` passes a **Regexp**
      (`/#{cache_key_base}/`) — and `FileStore#delete_matched` tolerates both today (via
      `String#match`, which accepts either). Forwarding a Regexp straight to
      `RedisCacheStore#delete_matched` would have crashed `dashboard_stats.rb`'s cache-clearing
      after cutover. Fixed by not using `RedisCacheStore#delete_matched` at all: scan Redis by hand
      (`SCAN` + `UNLINK` via the store's public `redis` accessor) and apply the matcher with
      `String#match?`, mirroring `FileStore`'s existing loose semantics exactly — both call sites
      keep working unmodified, no app code touched.
- [x] Implemented `clear`, found missing during a follow-up check (`Rails.cache.clear` was
      untouched by Step 3's original scope, so it silently inherited the base class's
      `raise NotImplementedError`). Delegates to both children. Note this makes `@redis_store`'s
      `namespace: 'cache'` option (Step 1/5) safety-critical, not just tidy:
      `RedisCacheStore#clear` does a scoped `delete_matched("*", namespace: ...)` when namespaced,
      but a full `FLUSHDB` on the whole shared instance if not — on a Redis shared with sessions,
      losing the namespace would turn `Rails.cache.clear` into "log every user out."
- [x] **CI:** unit test (`test/unit/redis_with_file_overflow_store_test.rb`) against a real local
      Redis (`redis://localhost:6379/15`, the same instance CI's `tests.yml` already starts on
      `localhost:6379` for session-store tests) plus a `Dir.mktmpdir` for the file side — 9 tests,
      all passing:
      - small item → written to Redis only, not on disk
      - large item → written to disk only, not in Redis
      - `delete` removes a key from whichever backend actually holds it
      - a key's size crossing the threshold between writes doesn't leave a stale duplicate in the
        previously-used backend
      - `delete_matched` removes matching keys from both backends, tested with **both** a glob
        String (`content_blob.rb` style) and a Regexp (`dashboard_stats.rb` style)
      - a cache file written in the plain `FileStore` format (simulating what's already sitting in
        `tmp/cache` today, pre-cutover) is read back cleanly through the new store's file-side
        reader — leftover pre-cutover entries can't cause a boot-time or request-time error once
        this store is live
      - `clear` removes entries from both backends
      - `clear` does **not** wipe Redis keys outside the configured namespace — proves the
        namespace-safety point above with a live assertion, not just a comment

Separately (informational): `rake tmp:cache:clear` is a raw `rm_rf Dir["tmp/cache/*"]`
(`railties/lib/rails/tasks/tmp.rake`) — it doesn't call `Rails.cache.clear` and has no idea what
cache store is configured. After cutover it only clears the filesystem-overflow side, leaving
Redis-cached items untouched. That's correct as-is and needs no change — the task is scoped to
`tmp/` by name and does exactly that; it's not meant to be a full cache clear. What *did* need
fixing: the deploy/setup scripts that call it (`script/update-from-git.sh`,
`script/mini-update-from-git.sh`, `script/load-docker.sh`, `script/import-docker-data.sh`, all via
`rake tmp:clear`) previously had no step that cleared the Redis side at all, so a deploy expecting
a fresh cache would leave stale Redis-cached values in place. Fixed:
- [x] Added `rake seek:clear_cache` (`lib/tasks/seek.rake`), a small reusable task wrapping
      `Rails.cache.clear`.
- [x] `lib/tasks/seek_upgrades.rake`'s `seek:upgrade` task already called `Rails.cache.clear`
      inline (alongside `tmp:clear`) — a pre-existing, independent confirmation that pairing the
      two is the right pattern. Switched it to invoke `seek:clear_cache` instead of duplicating
      the raw call, so there's one place that does it.
- [x] All four deploy/setup scripts now run `rake seek:clear_cache` alongside `rake tmp:clear`.

## Step 4 — Oversized-entry logging

- [x] Already landed as part of Step 3's `write_entry` (the overflow-to-disk branch calls
      `log_overflow` before delegating to the file backend), since the two were naturally the same
      code path — nothing left to implement here.
- [x] `log_overflow` uses a single plain `Rails.logger.info` call with the cache key and byte
      size, no rate-limiting/dedupe — logging isn't inbox noise the way email is, so every
      occurrence can be logged plainly.
- [x] **CI:** added the dedicated test this step calls for (`test/unit/redis_with_file_overflow_store_test.rb`):
      swaps `Rails.logger` for a `Logger` writing to a `StringIO` for the duration of the test,
      asserting an oversized write logs a line matching `overflow to disk`/`key=.../size=\d+`, and
      that a normal-sized write logs no such line. 11 tests passing overall.

## Step 5 — Wire up configuration

A real design problem surfaced while doing this, worth recording before the task list: the
original wording ("built from... `Seek::Config.cache_max_redis_item_size`") implied reading the
setting once at store-construction time. Verified empirically that `config/environments/*.rb` runs
*before* Zeitwerk autoloading is active for `lib/` — referencing any `Seek::` constant there raises
`NameError: uninitialized constant Seek`, and even if it didn't, capturing
`Seek::Config.cache_max_redis_item_size` once at boot would defeat Step 2's whole point (tunable
from the admin UI without a restart) and risk touching the database before it's safe to (e.g.
during `assets:precompile`, which boots Rails without guaranteed DB access).

- [x] `Seek::Caching::RedisWithFileOverflowStore.build(file_cache_path)` (added to the store class
      itself) is the single factory both environments call. `max_redis_item_size` is passed as a
      `Proc` (`-> { Seek::Config.cache_max_redis_item_size }`), resolved fresh on every write via a
      new `max_redis_item_size` method — the constant-loading problem is solved by
      `require_relative`-ing the store file directly at the top of each environment file (a plain
      Ruby `require`, independent of Zeitwerk, which is how Rails' own docs recommend handling
      custom cache/session stores needed this early); the DB-timing/live-tunability problem is
      solved by the Proc, since it's only *called* at actual write time, long after boot — the
      settings-DB read then goes through `Seek::Config`'s existing `RequestStore` + 1-week cache
      layer (`Seek::Config.settings_cache`), so it's not a raw DB hit per write either. Confirmed
      by booting both `development` and `production` (`RAILS_ENV=production`, `eager_load = true`)
      via `rails runner`/direct `Rails.application.initialize!` — no Zeitwerk conflict, `Rails.cache`
      resolves to the right class, and a real write/read round-trips.
- [x] `config/environments/production.rb`: `config.cache_store = :file_store, ...` replaced with
      `Seek::Caching::RedisWithFileOverflowStore.build("#{Rails.root}/tmp/cache")`.
- [x] `config.settings_cache_store` decided: pointed directly at a plain `RedisCacheStore` on the
      same Redis instance (no overflow wrapper — settings values are always small), with its own
      `namespace: 'settings-cache'` distinct from the main store's `'cache'` namespace — mirrors the
      isolation the old separate-directory `FileStore`s gave each other, just via namespace instead
      of directory.
- [x] `config/environments/development.rb` updated the same way, pointing the `FileStore` side at
      the existing dev cache path (`tmp/cache/dev-cache`) — same single Redis instance a developer
      already needs running for sessions, no environment-specific branching needed. No
      `maxmemory`/eviction policy expected on an ad hoc local `redis-server`; fine for dev (low
      volume, no correctness impact, just unbounded growth on a machine that restarts often anyway).
- [x] **CI:** left `config/environments/test.rb` on `:memory_store` for the suite as a whole (fast,
      isolated, avoids coupling every test to Redis availability). Added the dedicated test this
      step calls for (`test/unit/redis_with_file_overflow_store_test.rb`, "build constructs a
      working store the same way production.rb and development.rb do") — calls `.build` directly
      against a temp dir + the CI Redis service and round-trips a small and a large value through
      it, catching config-wiring mistakes without coupling the whole suite to Redis. Also added a
      dedicated test proving the `Proc` threshold is re-evaluated on every write, not just at
      construction (13 tests passing overall in this file).

## Step 6 — Cleanup & eviction scheduling

Redis and the filesystem overflow manage growth in fundamentally different ways — both need
covering, but not with the same mechanism.

**Redis — continuous eviction, not a scheduled job:**
- [x] `maxmemory-policy allkeys-lru` set in Step 1 (`docker-compose.yml` and its two variants) —
      this is what bounds Redis's growth; it evicts continuously under memory pressure, so no cron
      task is needed.
- [x] Implemented the optional periodic check as `CacheOverflowCleanupJob#log_redis_memory_stats`
      rather than extending `RegularMaintenanceJob` — piggybacking on the same daily job that
      already runs for the FileStore sweep, since both are cache-maintenance concerns, rather than
      RegularMaintenanceJob's unrelated grab-bag of DB cleanup tasks. Added
      `Seek::Caching::RedisWithFileOverflowStore#redis_memory_stats` (`INFO` sliced to
      `used_memory`/`used_memory_human`/`evicted_keys`) so the job doesn't need to reach into the
      store's private `@redis_store`. This directly sets up Step 8's monitoring requirement
      ("wire the `evicted_keys` monitoring from Step 6's optional periodic job"), so building it
      now avoids leaving that step with an undone dependency.
- [x] Not CI-testable for the `maxmemory-policy` setting itself — Redis server configuration, not
      application code, verified operationally (Step 1's `evicted_keys` monitoring). The logging
      *around* it is tested (below).

**FileStore overflow — needs an actual scheduled sweep:**
- [x] Audited and added `expires_in` to the 12 large-item `Rails.cache.fetch` call sites: spreadsheet
      XML/CSV (`lib/seek/templates/reader.rb`, `lib/seek/data/spreadsheet_explorer_representation.rb`),
      cached workbook objects (`app/helpers/search_helper.rb`,
      `lib/seek/assets_standard_controller_actions.rb`), RightField CSV/RDF
      (`lib/rightfield/rightfield.rb`), the generic text-blob renderer cache
      (`app/helpers/assets_helper.rb`), notebook HTML (`lib/seek/renderers/notebook_renderer.rb`) —
      all `expires_in: 30.days`, since these keys are content-hash-derived (`content_blob.cache_key`)
      or tied to an immutable content blob, so a stale entry is simply orphaned on content change,
      never served incorrectly; long TTL just bounds eventual disk reclaim. Ontology hierarchies
      (`lib/seek/ontologies/ontology_reader.rb`) and EBI OLS (`lib/ebi/ols_client.rb`, both call
      sites) got `expires_in: 7.days` instead — their cache keys are *not* content-versioned (a
      bundled ontology file path, or a raw external-API term IRI), so a shorter TTL is what
      actually lets upstream changes get picked up, not just a disk-growth bound.
- [x] Created `CacheOverflowCleanupJob < ApplicationJob` (`RUN_PERIOD = 1.day`). Calls
      `Rails.cache.cleanup`, which required adding `cleanup` to `RedisWithFileOverflowStore` itself
      (delegating only to the file side — confirmed `RedisCacheStore#cleanup` is literally
      `super` → `raise NotImplementedError`, "manual cleanup is not supported", so calling it on
      the Redis side would have crashed the job).
- [x] Scheduled in `config/schedule.rb`: `every CacheOverflowCleanupJob::RUN_PERIOD, at: offset(4)`
      — offset 4 is distinct from `RegularMaintenanceJob`/`AuthLookupMaintenanceJob` (offset 1),
      `LifeMonitorStatusJob` (offset 2), and `Galaxy::ToolMap` (offset 3). Verified with
      `bundle exec whenever` that it generates a correct, distinctly-timed crontab entry.
- [x] Updated `test/integration/schedule_test.rb` to account for the new runner — the existing
      `should read schedule file` test pops each expected runner and asserts none are left over, so a
      new scheduled job must be registered there or the test fails ("Found untested runner(s)"). This
      was missed initially and only surfaced in CI (run 28936858354) because Step 6 landed after the
      earlier green run; added the `CacheOverflowCleanupJob.perform_later` expectation
      (`[1.day, { at: '4:00am' }]`).
- [x] Disk-space monitoring note (no separate ops runbook exists in this repo, so recorded here):
      TTL + daily cleanup bounds the overflow directory's growth but isn't instantaneous — between
      sweeps, disk usage can still climb. Worth an alert threshold on the `tmp/cache` filesystem
      (or volume, in Docker) separately from the `evicted_keys` Redis alerting from Step 8.
- [x] **CI:** `test/unit/jobs/cache_overflow_cleanup_job_test.rb` — swaps in a real
      `RedisWithFileOverflowStore` against a temp dir + the CI Redis service (mirroring
      `redis_with_file_overflow_store_test.rb`'s own pattern, not `regular_maintenance_job_test.rb`'s
      DB-fixture style, since this job's state lives in the cache stores, not the database): write
      one expired and one non-expired large entry, run the job, assert only the expired file is
      gone; plus two tests for the memory-stats logging (logs when the store supports
      `redis_memory_stats`, silently no-ops when it doesn't — e.g. test env's `:memory_store`).
      4 tests total.
- [x] **CI:** `test/unit/cache_overflow_call_sites_test.rb` — spot-checks all 12 updated call sites
      via a static regex match against each file's source, asserting `expires_in:` is still present
      on the exact `Rails.cache.fetch` line. Deliberately lightweight (no need to exercise RightField's
      Java process, nbconvert, or live network calls just to check an option is passed) but
      verified for real: temporarily stripped `expires_in` from one call site and confirmed the
      test fails with a clear message, then restored it and confirmed it passes again.

## Step 7 — Final testing & verification

Steps 1–6 each land their own CI coverage alongside the code they test, so this step is the final
cross-cutting pass, not where testing starts:

- [ ] Full CI suite green, including all the tests added incrementally in Steps 1–6.
- [x] End-to-end integration test spanning the whole path
      (`test/integration/redis_overflow_cache_test.rb`, 5 tests): builds the store via `.build` and
      installs it as `Rails.cache` exactly as production/development do, then drives the real
      `Rails.cache` mechanism rather than the store directly — small value → Redis, incompressible
      large value → disk **and** an overflow log line; the threshold read live from `Seek::Config`
      on every write (same key routed to disk under a tiny threshold, to Redis under a large one, with
      the stale copy removed); structured-value round-trip + delete; `clear` empties both backends
      while leaving a `session:`-style key in another Redis namespace intact; and `delete_matched`
      exercised through the real `ContentBlob#clear_sample_type_matches` call site against the live
      overflow store. Closes review finding **L5**. (Uses an incompressible `SecureRandom.hex`
      payload where disk placement is asserted, since a repetitive value would compress below the
      threshold and land in Redis.)
- [ ] Manual verification (`/verify`): exercise the spreadsheet-explore view, notebook rendering,
      RightField extraction, and ontology browsing; confirm large payloads land on disk under
      `tmp/cache` and small/frequent values (dashboard stats, settings, list-item titles) land in
      Redis.
- [ ] Confirm session login and Action Cable are unaffected (separate db on the shared instance).
- [ ] Run the full app locally without Docker (`bundle exec rails server` against a local
      `redis-server`) and confirm caching, sessions, and the filesystem overflow all work with no
      Docker-specific assumptions.

## Step 8 — Session-store impact if the cache fills Redis

Step 1 flagged, as a documentation note, that `maxmemory-policy` is instance-wide, so cache growth
can in principle evict session keys, not just cache keys. That risk deserves more than a note: a
cache miss is invisible and cheap (re-fetch, maybe a slow request); a session eviction is user
-visible (a silent forced logout before the 30-minute `expire_after`) and easy to miss in testing
since it only shows up under real memory pressure.

- [ ] Confirmed via the `redis-store` gem (`Redis::Store::Ttl#set`, `lib/redis/store/ttl.rb`) that
      session keys already carry a real Redis-level `EXPIRE` matching `expire_after: 30.minutes`
      (`config/initializers/session_store.rb`), refreshed on every write. This rules out one
      tempting mitigation: switching `maxmemory-policy` from `allkeys-lru` to `volatile-lru` would
      *not* protect sessions, since `volatile-lru` only spares keys with **no** TTL, and session
      keys have one — it would just as happily evict them. Any real fix has to be about capacity
      and visibility, not a policy trick.
- [ ] Simulate the failure mode before launch: point a local/staging Redis at a small `maxmemory`
      (e.g. 10mb), log in to create a handful of real sessions, then write cache entries until
      eviction kicks in (`INFO stats` → `evicted_keys` climbing). Confirm directly whether active
      session keys get evicted under sustained cache pressure, rather than assuming from the LRU
      docs — this is the one part of the shared-instance decision that's cheap to verify for real.
- [ ] Set `maxmemory` (Step 1) with headroom sized from a measured peak: concurrent active
      sessions × average serialized session size, plus the expected cache working set, plus a
      safety margin — not an arbitrary round number.
- [ ] Wire the `evicted_keys` monitoring from Step 6's optional periodic job to something that
      actually gets looked at (log line is enough initially, admin-alerting can follow later) —
      the goal is that a rising `evicted_keys` count is noticed as "sessions may be getting dropped
      early," not discovered via a user complaint.
- [ ] Document the escalation path in the ops runbook if `evicted_keys` alerts fire repeatedly:
      raise `maxmemory` first (cheapest fix); if cache growth keeps outpacing that, splitting
      cache and sessions onto separate Redis instances is the real fix — flagged here as a known
      future step, not built now, since Step 1's decision to share one instance was deliberately
      scoped to SEEK's current scale.
- [ ] **CI:** not meaningfully testable in the normal suite — real LRU eviction ordering depends on
      timing and memory pressure that isn't deterministic enough to assert on reliably. Covered by
      the manual simulation above instead, plus the existing session-store tests (unaffected by
      this step, since nothing here changes session code, only capacity planning and monitoring
      around the store it already uses).

## Review findings (to address)

Full write-up: `redis_filestore_cache_review_2655_2026-07-07.md` (review of `main...redis-cache-store-2655`,
Steps 1–6). None are blockers; listed here in the suggested order to work through. Severity:
**[M]** medium (fix before prod reliance), **[L]** low, **[I]** informational / pre-existing.

- [x] **[M3]** `cache_max_redis_item_size` has no floor — a blank/`0` value (`admin_controller.rb:354`
      sets it unconditionally, `to_i`s to `0`) routes **every** entry to disk. Rather than guard
      against this, we treat `0` as a legitimate way to turn Redis caching off entirely (everything
      on the filesystem) — the admin help text now documents this behaviour explicitly so it reads
      as an intentional switch, not a silent misconfiguration.
- [x] **[L5] / Step 7** the store was never exercised as `Rails.cache` in the suite (test env stays
      on `:memory_store`). **Fixed** by `test/integration/redis_overflow_cache_test.rb`, which installs
      the real overflow store as `Rails.cache` and drives it through the `Rails.cache` API and the
      `ContentBlob#clear_sample_type_matches` call site — exercising the threshold routing, overflow
      logging, double key-normalisation, namespace-scoped `clear`, and `delete_matched` for real. See
      Step 7 above.
- [x] **[M1]** every small cache write does a filesystem `stat` — `write_to_redis` calls
      `FileStore#delete_entry` (→ `File.exist?`) to clear a stale disk copy. **Decision: keep it.**
      The review's option (c) (drop the pre-delete, rely on read-checks-Redis-first) is actually a
      latent correctness bug: a stable key can move backends between writes, and once the fresh copy
      is evicted (`allkeys-lru`) or TTL-expires, a read falls through to the surviving stale copy in
      the other backend and serves an out-of-date value — so the cross-backend delete is a
      correctness invariant. The cost is also smaller than it first looks: writes only happen on a
      cache *miss*, and steady-state *hits* return from Redis without touching the filesystem at all.
      Documented the invariant and the miss-only cost in a code comment above `write_to_redis` /
      `write_to_file`; the "no stale duplicate after a threshold crossing" unit test already asserts
      the invariant.
- [x] **[M2]** `delete_matched` pulled the entire `cache:*` namespace to the client and filtered in
      Ruby, O(all cache keys) per call. **Fixed** by narrowing the server-side `SCAN` with a derived
      `MATCH` pattern: extract the literal substring every matching key is *guaranteed* to contain
      (`guaranteed_literal_substring` — leading literal run, dropping a quantified trailing char) and
      scan `"<prefix>*<literal>*"`, so Redis pre-filters. The exact Ruby matcher is still applied to
      the (now much smaller) candidate set, so semantics and both-backend consistency are unchanged —
      the MATCH is a strict *superset*, never tighter, so no key that should be deleted is skipped.
      Works for both real call sites (`"st-match-#{id}*"` → `*st-match-<id>*`, `/admin_dashboard_stats/`
      → `*admin_dashboard_stats*`); falls back to the old full-namespace scan when no literal can be
      extracted (e.g. an anchored/leading-metacharacter regex). Covered by new unit tests
      (`redis_with_file_overflow_store_test.rb`: prefilter-active deletion, literal extraction incl.
      the quantifier-drop and no-literal fallback cases).
- [x] **[L1]** Investigating the unanchored-regex footgun revealed the primary call site was worse
      than the review thought: `content_blob#clear_sample_type_matches` used `"st-match-#{id}*"` (a
      **hyphen**), but the cached match results live under an *array* key
      (`['st-match', blob, content_blob, …]`, `sample_type_template_concerns.rb:48`) that normalizes
      to `st-match/content_blobs/<id>-…` (a **slash** then the blob `cache_key`). Confirmed
      empirically that the old pattern matched **nothing** — a pre-existing no-op left behind when the
      key was refactored to an array. **Fixed** the call site to match this blob's
      `content_blobs/<id>-` segment anywhere within an `st-match/` key (`%r{st-match/.*content_blobs/#{id}-}`),
      which covers the blob appearing in either the matched-blob or the sample-type-template position;
      the trailing `-` bounds the id so blob 12 doesn't also clear blob 120. Added a `content_blob_test`
      asserting a real array-key entry is cleared from either position and an unrelated entry is left
      intact. (The dashboard_stats call site, `/admin_dashboard_stats/`, was already correct — its
      keys really are prefixed that way.) The general "String matcher = unanchored Ruby regex, not a
      glob" property of `delete_matched` remains, faithful to FileStore, but no live call site now
      relies on it.
- [ ] **[L2]** `delete_matched` assumes a single Redis node (`@redis_store.redis`), where the
      original iterated `Redis::Distributed#nodes`. No practical impact on SEEK's single-`REDIS_URL`
      setup, but strictly less robust than what it replaced.
- [ ] **[L3]** payload is serialized twice per write — once in `write_entry` to measure `bytesize`,
      then again by the child store. Avoidable CPU on the large-overflow path specifically; also the
      size comparison silently depends on parent and child stores sharing coder/compress settings.
      Worth a comment noting that invariant.
- [ ] **[L4]** `settings_cache_store` is now a plain `RedisCacheStore` on the request hot path — a
      Redis blip means a per-request DB read for settings until recovery (degrades safely, but a new
      network coupling worth noting for capacity/latency planning).
- [ ] **[I1]** `clear` / deploy-script `seek:clear_cache` wipes all of `tmp/cache`, including
      `bootsnap` and sprockets caches → slower next boot. Pre-existing (old config was also
      `:file_store, "tmp/cache"`) and deploys already run `tmp:clear` first, so no new harm. If it
      ever matters, point the overflow FileStore at a dedicated subdir (e.g. `tmp/cache/rails-cache`).
- [ ] **[I2] / Step 8** `maxmemory 512mb` is a shared, hardcoded, unvalidated budget across
      sessions + settings-cache + main cache with `allkeys-lru` — cache pressure can evict session
      keys. Size it against the real working set and surface `evicted_keys` (already tracked in
      Step 8).
- [ ] **[I3]** container rename `seek-session-store` → `seek-redis` is a minor external-compat break
      for any out-of-repo ops tooling that references the old name. Worth a line in the
      release/upgrade notes.

## Test-infrastructure note — running the store tests without a live Redis (revisit later)

- [ ] **Let the store tests run without a live Redis.**
`test/unit/redis_with_file_overflow_store_test.rb` requires a real Redis (`redis://localhost:6379/15`)
for the whole file — `setup` builds a `RedisCacheStore` and `teardown` calls `clear`, so even the
pure-logic tests inherit the dependency. CI already runs `redis:8.6-alpine`, so this is fine there;
it only bites when running the suite locally without Redis. Options considered, to revisit if it
becomes a pain:

- **VCR cassettes — not applicable.** VCR records at the HTTP layer (via WebMock); the `redis` gem
  speaks the RESP protocol over a raw TCP socket, which WebMock/VCR don't intercept. (It's WebMock's
  `allow_localhost: true` that lets the real Redis connection through in tests today.)
- **In-memory fake gem.** `mock_redis` (0.55.0, current, tracks redis-rb 5.x) is the only viable
  candidate — `fakeredis` (0.9.2) is stale and won't work with this project's `redis 5.4.1`. Neither
  is currently a project dependency. Caveats: (1) wiring a `MockRedis` into `RedisCacheStore` isn't
  trivial since AS drives its client through `redis-client` internally — needs verifying, not
  assuming; (2) fidelity gap on exactly the behaviours this store leans on (`SCAN` cursor batching,
  `UNLINK`, `maxmemory`/`allkeys-lru` eviction), so a green test against the fake could mask a real
  -Redis failure. Adds a test dependency for questionable benefit given CI has a real server.
- **Cheapest win (no new dependency).** Split the two pure-string tests (`guaranteed_literal_substring`,
  `redis_scan_pattern`) into a sibling test class that doesn't construct the Redis store in `setup`,
  so at least the matcher-derivation logic runs anywhere. Recommended if/when this is worth doing.
