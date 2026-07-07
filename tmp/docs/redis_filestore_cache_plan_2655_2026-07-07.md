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

- [ ] Create `lib/seek/caching/redis_with_file_overflow_store.rb`,
      `Seek::Caching::RedisWithFileOverflowStore < ActiveSupport::Cache::Store`, constructed with
      a `RedisCacheStore` instance, a `FileStore` instance, and a max-size value.
- [ ] Implement `write_entry`, `read_entry`, `delete_entry` per the architecture above
      (serialize once, measure `bytesize`, route, and clean up the non-chosen backend).
- [ ] Implement `delete_matched` delegating to both backends.
- [ ] **CI:** unit test the store directly against the CI Redis service (`localhost:6379`, already
      started by `tests.yml`) plus a `Dir.mktmpdir` for the file side — this is the core
      correctness suite everything else builds on, so it lands in the same step as the
      implementation, not deferred:
      - small item → written to Redis only, not on disk
      - large item → written to disk only, not in Redis
      - `delete` removes a key from whichever backend actually holds it
      - a key's size crossing the threshold between writes doesn't leave a stale duplicate in the
        previously-used backend
      - `delete_matched` removes matching keys from both backends (regression coverage for the two
        existing call sites that rely on it: `app/models/content_blob.rb:321`,
        `lib/seek/stats/dashboard_stats.rb:76`)
      - a cache file written in the old plain-`FileStore` format (i.e. what's already sitting in
        `tmp/cache` today, pre-cutover) is read back cleanly as a miss (or a compatible hit)
        through the new store's file-side reader — leftover pre-cutover entries can't cause a
        boot-time or request-time error once this store is live

## Step 4 — Oversized-entry logging

- [ ] On the overflow-to-disk path in `RedisWithFileOverflowStore`, log a single line via
      `Rails.logger.info` including the cache key and byte size — enough to `grep` the log for
      overflow activity or wire up log-based alerting later if it's ever needed, without an email
      firing on every routine large-item write.
- [ ] No rate-limiting/dedupe needed — logging isn't inbox noise the way email is, so every
      occurrence can be logged plainly.
- [ ] **CI:** unit test asserting the log line is emitted (with key and size) for an oversized
      write, and not emitted for a normal-sized write.

## Step 5 — Wire up configuration

- [ ] In `config/environments/production.rb`, replace
      `config.cache_store = :file_store, "#{Rails.root}/tmp/cache"` with an instance of
      `Seek::Caching::RedisWithFileOverflowStore` built from the derived cache-db URL (Step 1),
      `Rails.root.join('tmp/cache')`, and `Seek::Config.cache_max_redis_item_size`.
- [ ] Decide the fate of `config.settings_cache_store` (currently its own `FileStore`, used for
      hot, tiny config reads on nearly every request): recommend pointing it at the same Redis
      cache db directly (no overflow wrapper needed — settings values are always small), rather
      than maintaining a third store type.
- [ ] Update `config/environments/development.rb` the same way, since it's the same single Redis
      instance a developer already needs running for sessions — no environment-specific branching
      needed. `maxmemory`/eviction policy is not expected to be configured on an ad hoc local
      `redis-server`; that's fine for dev (low volume, no correctness impact, just unbounded
      growth on a machine that gets restarted often anyway). The FileStore side of the overflow
      store continues to use the existing dev cache path (`tmp/cache/dev-cache`).
- [ ] **CI:** leave `config/environments/test.rb` on `:memory_store` for the suite as a whole
      (fast, isolated, avoids coupling every test to Redis availability), but add one dedicated
      test that builds the store the same way `production.rb`/`development.rb` do and asserts it
      constructs without error and round-trips a value against the CI Redis service + a temp
      dir — this catches config-wiring mistakes (bad URL derivation, wrong constant, etc.)
      without making the whole suite depend on Redis.

## Step 6 — Cleanup & eviction scheduling

Redis and the filesystem overflow manage growth in fundamentally different ways — both need
covering, but not with the same mechanism.

**Redis — continuous eviction, not a scheduled job:**
- [ ] Confirm `maxmemory-policy allkeys-lru` (set in Step 1) is active — this is what bounds
      Redis's growth; it evicts continuously under memory pressure, so no cron task is needed.
- [ ] Optional: add a lightweight periodic check (extend `RegularMaintenanceJob`, or a new small
      job) that logs Redis `INFO memory` (`used_memory`, `evicted_keys`) for ops visibility.
- [ ] Not CI-testable as such — `maxmemory-policy` is Redis server configuration, not application
      code. Verified operationally (Step 1's `evicted_keys` monitoring), not by a test suite.

**FileStore overflow — needs an actual scheduled sweep:**
- [ ] `ActiveSupport::Cache::FileStore#cleanup` only deletes entries with an **expired** TTL — it
      does nothing for entries written without `expires_in`. Audit the large-item call sites that
      will overflow to disk (spreadsheet XML/CSV, notebook HTML, RightField CSV/RDF, ontology
      hierarchies, cached workbook objects, the generic text-blob renderer cache) and add a
      sensible `expires_in` to each `Rails.cache.fetch` call so cleanup has something to reap —
      long-lived is fine (e.g. 30 days) since most of these keys are already content-derived and
      self-invalidate on content change; shorter for anything hitting an external API (e.g. the
      EBI OLS ontology-descendants cache) so upstream changes are eventually picked up.
- [ ] Create `CacheOverflowCleanupJob < ApplicationJob` (mirroring `RegularMaintenanceJob`'s
      shape) that calls `.cleanup` on the filesystem side of `RedisWithFileOverflowStore`.
- [ ] Schedule it in `config/schedule.rb` using the existing `whenever` pattern:
      `every 1.day, at: offset(N) do runner "CacheOverflowCleanupJob.perform_later" end`, offset
      to avoid colliding with `RegularMaintenanceJob` / `AuthLookupMaintenanceJob`.
- [ ] Add a disk-space monitoring note to the ops runbook for the overflow cache path — TTL +
      cleanup bounds growth but doesn't make it instantaneous; worth an alert threshold.
- [ ] **CI:** unit test for `CacheOverflowCleanupJob`
      (`test/unit/jobs/cache_overflow_cleanup_job_test.rb`, mirroring
      `test/unit/jobs/regular_maintenance_job_test.rb`) — write one expired and one non-expired
      entry directly to the file-side store, run the job, assert only the expired entry is gone.
- [ ] **CI:** spot-check that the large-item call sites updated in this step actually pass
      `expires_in` (e.g. a shared assertion helper used across their existing tests) — guards
      against a future call site being added to the overflow path without a TTL, which would
      silently defeat the cleanup job.

## Step 7 — Final testing & verification

Steps 1–6 each land their own CI coverage alongside the code they test, so this step is the final
cross-cutting pass, not where testing starts:

- [ ] Full CI suite green, including all the tests added incrementally in Steps 1–6.
- [ ] End-to-end integration test spanning the whole path: write an item just under and just over
      the configured threshold through a real call site (not the store directly), confirm correct
      backend placement end-to-end and that only the oversized write logs an overflow entry.
- [ ] Manual verification (`/verify`): exercise the spreadsheet-explore view, notebook rendering,
      RightField extraction, and ontology browsing; confirm large payloads land on disk under
      `tmp/cache` and small/frequent values (dashboard stats, settings, list-item titles) land in
      Redis.
- [ ] Confirm session login and Action Cable are unaffected (separate db on the shared instance).
- [ ] Run the full app locally without Docker (`bundle exec rails server` against a local
      `redis-server`) and confirm caching, sessions, and the filesystem overflow all work with no
      Docker-specific assumptions.
