# Code Review — Redis + FileStore Hybrid Caching (`redis-cache-store-2655`)

Review of the full branch diff (`main...redis-cache-store-2655`, 13 commits, Steps 1–6 of the
plan) against `main`. Companion to the implementation plan
(`redis_filestore_cache_plan_2655_2026-07-07.md`).

Scope reviewed: the `RedisWithFileOverflowStore` class, prod/dev config wiring, the
`cache_max_redis_item_size` setting + admin plumbing, `CacheOverflowCleanupJob`, the `expires_in`
call-site changes, the docker-compose/deploy-script changes, and the new tests.

Overall: the design is sound and the implementation is faithful to the plan. Test coverage of the
store in isolation is good. Nothing here is a blocker, but there are a few real correctness/perf
footguns worth addressing before this is relied on in production, plus one genuine end-to-end
coverage gap (already tracked as Step 7).

Severity key: **[M]** medium (should fix before prod reliance), **[L]** low (worth doing),
**[I]** informational / pre-existing.

---

## [M1] Every small cache write now performs a filesystem `stat`

`lib/seek/caching/redis_with_file_overflow_store.rb:93-96` (`write_to_redis`)

```ruby
def write_to_redis(key, entry, **options)
  @file_store.send(:delete_entry, @file_store.send(:normalize_key, key, options), **options)  # <-- File.exist? per write
  @redis_store.send(:write_entry, @redis_store.send(:normalize_key, key, options), entry, **options)
end
```

Every write that lands in Redis (i.e. the overwhelming majority of cache writes — dashboard stats,
list-item titles, citation lookups, etc.) first calls `FileStore#delete_entry`, which does a
`File.exist?(path)` syscall (and a directory-tree walk to build the path). This is a new
per-write disk `stat` on the hot path that did not exist when the cache was pure Redis or pure
FileStore.

The cleanup-the-other-backend step only actually does anything on the rare occasion a key's size
crosses the threshold between writes. For the common case it is pure overhead.

**Options:** (a) accept it — SEEK is not high-QPS, and a `stat` is cheap; (b) only clean the other
backend when we have reason to think the key might be there (hard to know cheaply); (c) accept
occasional stale duplicates and let TTL + `cleanup` reap them, dropping the pre-delete entirely on
the write-to-Redis path (the read path already checks Redis first, so a stale file copy under a key
that now lives in Redis would never be served). Option (c) removes the hot-path cost at the price
of transient disk usage. Worth a deliberate decision rather than leaving it implicit.

## [M2] `delete_matched` pulls the entire cache namespace to the client

`lib/seek/caching/redis_with_file_overflow_store.rb:132-151`

The Redis side of `delete_matched` does a full `SCAN` over `cache:*` and filters every key in Ruby
with `String#match?`:

```ruby
scan_pattern = prefix ? "#{prefix}*" : '*'   # matches ALL cache keys
...
matching = keys.select { |k| ... bare_key.match?(matcher) }
```

The original `RedisCacheStore#delete_matched` pushes the glob to Redis (`SCAN ... MATCH pattern`),
so filtering happens server-side. The new implementation cannot, because it deliberately supports
`Regexp` matchers (see [L1]) — but the consequence is that both existing call sites now scan the
**entire** cache namespace client-side on every invocation:

- `app/models/content_blob.rb:321` — `clear_sample_type_matches`, runs on content-blob change
- `lib/seek/stats/dashboard_stats.rb` — `clear_caches`, runs on dashboard interactions

With a large cache this is O(all cache keys) per call. For the `String` (glob) case specifically,
it would be cheap to translate to a Redis `MATCH` pattern and let the server filter, falling back to
the full client-side scan only for `Regexp` matchers. Worth doing if either call site turns out to
be hot.

## [M3] `cache_max_redis_item_size` has no floor — a blank value silently disables the Redis tier

`app/controllers/admin_controller.rb:354`, `lib/seek/caching/redis_with_file_overflow_store.rb:81`

Confirmed empirically: setting the admin field to blank stores `""`, which (`convert: :to_i`)
reads back as `0`, and then **every** entry — even a 4-byte value — overflows to the filesystem:

```
threshold when blank: 0
tiny value with blank threshold -> redis? false file? true
```

The admin controller sets it unconditionally with no validation:

```ruby
Seek::Config.cache_max_redis_item_size = params[:cache_max_redis_item_size]
```

So an admin who clears the field (or any future form/bug that posts it empty) silently turns the
whole feature off and routes 100% of cache traffic to disk — the exact opposite of the intent —
with no error and no log line. (The neighbouring `max_cachable_size`/`hard_max_cachable_size`
settings share the same unguarded pattern, so this isn't unique to the new code, but it's more
consequential here.)

**Fix:** validate a sensible minimum on save (reject/clamp `<= 0`), and/or treat a non-positive
configured value as "fall back to the default" in the store rather than "send everything to disk".

## [L1] `delete_matched` treats a String matcher as a Ruby regex, not a Redis glob

`lib/seek/caching/redis_with_file_overflow_store.rb:127`

`bare_key.match?(matcher)` — when `matcher` is a `String` (e.g. `content_blob.rb`'s
`"st-match-#{id}*"`), Ruby coerces it to a `Regexp`. This is intentional and **consistent with the
old production FileStore** (`FileStore#delete_matched` also does `key.match(matcher)`), so it is not
a regression. But it means:

- the `*` in `"st-match-12*"` is a regex quantifier, not a glob wildcard, and the match is
  **unanchored** — so `delete_matched("st-match-12*")` also deletes `st-match-13...` (the regex
  `/st-match-12*/` matches the `st-match-1` substring). This pre-existing FileStore footgun is now
  cemented into the Redis path too.

Low priority because it faithfully preserves the behaviour these call sites already had on
FileStore, but worth a comment at the call sites (or anchoring the match) if anyone ever tightens
it up.

## [L2] Distributed-Redis case not handled in `delete_matched`

`lib/seek/caching/redis_with_file_overflow_store.rb:150`

`@redis_store.redis.then { |c| scan_and_unlink(c, ...) }` assumes a single node. The original
`RedisCacheStore#delete_matched` iterates `c.nodes` for `Redis::Distributed`. SEEK uses a single
`REDIS_URL`, so this is not a practical problem today, but the new code is strictly less robust than
what it replaces should a clustered setup ever be introduced.

## [L3] Payload is serialized twice on every write

`lib/seek/caching/redis_with_file_overflow_store.rb:79` + `write_to_redis`/`write_to_file`

`write_entry` calls `serialize_entry` purely to measure `bytesize`, then hands the raw `entry` to
the child store, which serializes it **again** to actually store it. For large payloads (precisely
the overflow case — spreadsheet XML, notebook HTML) this means serializing and gzip-compressing a
big object twice per write. Correctness is fine (both coders are configured identically via
`build`), but it's avoidable CPU. Also note the correctness of the size comparison silently depends
on the parent and child stores sharing coder/compression settings — fine today, fragile if anyone
customises one store's `:coder`/`:compress` later. A short comment noting that invariant would help.

## [L4] `settings_cache_store` now depends on Redis on the request hot path

`config/environments/production.rb:64`, `development.rb:35`

`Seek::Config` reads go through `settings_cache_store`, now a plain `RedisCacheStore`, on nearly
every request (first read per request, then `RequestStore`-memoised). This is mostly an improvement
(shared across processes instead of per-node files) and degrades safely if Redis is down
(`RedisCacheStore` failsafe → block re-runs → per-request DB load). Flagging only because it moves a
previously disk-local, always-available read onto the network: a Redis blip now means a DB read per
request for settings until it recovers, where before it was a local file read. Acceptable, but a new
coupling worth being aware of for capacity/latency planning.

## [L5] Store is not exercised as `Rails.cache` anywhere in the automated suite

`config/environments/test.rb` stays on `:memory_store`, so every real call site
(`Rails.cache.fetch(...)` across ~30 files) runs against `MemoryStore` in CI, not against
`RedisWithFileOverflowStore`. The store is well covered in isolation
(`test/unit/redis_with_file_overflow_store_test.rb`, 14 tests) but the **integration** — real call
sites, the double key-normalisation path, `delete_matched` invoked through `content_blob` /
`dashboard_stats` rather than directly — has no CI coverage. This is exactly the "end-to-end
integration test through a real call site" that the plan defers to **Step 7 (not yet done)**, so
it's tracked; noting here so it isn't lost.

## [I1] `clear` (and the new deploy-script `seek:clear_cache`) wipes all of `tmp/cache`, including bootsnap

`lib/seek/caching/redis_with_file_overflow_store.rb:48-51`

The file side's `cache_path` in production is `tmp/cache`, which also contains `tmp/cache/bootsnap`
and `tmp/cache/assets`. `FileStore#clear` removes all children of the cache path, so
`Rails.cache.clear` nukes the bootsnap compile cache and sprockets cache (→ slower next boot). This
is **pre-existing** — the old prod config was also `:file_store, "tmp/cache"` — and the deploy
scripts already run `tmp:clear` (which deletes `tmp/cache/*` anyway) immediately before the new
`seek:clear_cache`, so no new harm. Mentioned only because the blast radius of `Rails.cache.clear`
is wider than "the cache" and it's easy to forget. If it ever matters, point the overflow FileStore
at a dedicated subdirectory (e.g. `tmp/cache/rails-cache`) instead of the shared `tmp/cache` root.

## [I2] Redis `maxmemory 512mb` is a shared, hardcoded, unvalidated budget

`docker-compose.yml:59-68` (and the two variants)

Sessions + settings-cache + main cache now share one 512 MB Redis with `allkeys-lru`, so cache
pressure can evict **session** keys → surprise logouts. This is already called out as the central
risk of the shared-instance decision and is the subject of the (pending) **Step 8** — recording
here only that the 512 MB number is a placeholder that needs sizing against the real
session + cache working set, and that `evicted_keys` monitoring (built into
`CacheOverflowCleanupJob`) needs somewhere to actually surface.

## [I3] Container rename is a minor external-compat break

`docker-compose*.yml` — `seek-session-store` → `seek-redis`. Correct and consistent across all three
compose files, and nothing in-repo references the old name. But any out-of-repo ops tooling that
does `docker exec seek-session-store ...` will break. Worth a line in the release/upgrade notes.

---

## Things that are correct and were checked (no action needed)

- **No `Rails.cache.increment`/`decrement`/`read_multi`/`fetch_multi` usage** in the codebase, so
  the store not overriding `increment`/`decrement` (base class raises `NotImplementedError`) is not
  a regression. Verified by grep.
- **No call site passes an explicit `namespace:` option** to `Rails.cache`, so the double
  key-normalisation (parent store + child store) can't produce a double-namespace surprise in
  practice. (It would still round-trip correctly if one did, since read and write are symmetric.)
- **`clear` is namespace-scoped on Redis** (`RedisCacheStore#clear` → `delete_matched "*",
  namespace: 'cache'`, not `FLUSHDB`), and there is a dedicated test proving it doesn't touch keys
  outside the namespace — so sessions survive a cache clear. Good.
- **TTLs propagate to both backends** — `expires_in` reaches Redis (native `PX`) and the file
  Entry (`expires_at`), and `FileStore#cleanup` reaps expired file entries. The `CacheOverflowCleanupJob`
  test confirms only-expired reaping.
- **Boot ordering** — `require_relative` + `Proc` threshold means no `Seek::` constant reference and
  no DB/Redis access during `config/environments/*.rb` evaluation; confirmed green in CI including
  `assets:precompile` and `seek:upgrade`.
- **`seek:clear_cache` degrades safely** if Redis is down during a deploy (`RedisCacheStore#clear`
  is failsafe), so it won't break `update-from-git.sh`.

---

## Suggested priority order to address

1. **[M3]** floor/validate `cache_max_redis_item_size` (cheap, prevents silent feature-off).
2. **[L5] / Step 7** add one end-to-end test with the overflow store as `Rails.cache` through a real
   call site (also exercises [M1]/[M2]/[L1] paths for real).
3. **[M1]** decide explicitly whether the per-write file `stat` stays or the write path drops the
   pre-delete.
4. **[M2]** translate the `String` matcher case to a server-side Redis `MATCH` if either
   `delete_matched` call site proves hot.
5. **[I2] / Step 8** size `maxmemory` and wire up `evicted_keys` alerting.
6. Everything else ([L1]–[L4], [I1], [I3]) — comments / release notes / nice-to-haves.
