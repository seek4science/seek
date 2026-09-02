# FAIRDOM-SEEK 1.19.0 Release Notes

## New Features

- **"Did you mean …?" spelling suggestions in search** — The search results page now offers a spelling suggestion when a query looks misspelled. The Solr spellchecker was previously non-functional, as it pointed at an empty field with nothing feeding it, so the dictionary was always empty; a dedicated spelling field now backs it (#2690, #2700)
- **Direct download of the main workflow file** — The main workflow file of a workflow can now be downloaded straight from the show page via a split download button, instead of having to browse the Files tab and hunt for it. This makes it much easier to grab the link for something like a Jupyter notebook (#952)
- **Activity metrics in the JSON API** — View, download and run counts (the figures shown in the right-hand column of the show page) are now included in the `meta` property of the JSON serialisation. They only appear for types that record them, so a Data file will not report runs (#2027, #2726)
- **Redis-backed caching with filesystem overflow** — `Rails.cache` now uses Redis, via a new `Seek::Caching::RedisWithFileOverflowStore` that keeps small entries in Redis and overflows anything larger than the configurable `cache_max_redis_item_size` threshold to the filesystem. Reads check Redis first, then disk, and a write removes the stale copy from the other backend so a key that changes size cannot leave a duplicate behind. Redis cache statistics are surfaced on the admin dashboard, and maxmemory and the eviction policy are configurable (#2655, #2664)
- **Redis session store** — Sessions are now stored in Redis rather than the ActiveRecord session store, with the `sessions` table dropped. The session cookie can be scoped to an FQDN, and the `secure` attribute is configurable through environment variables (#2569, #2610)
- **Password authentication for Redis** — Redis connections now support password authentication, which is needed for instances using a centralised or shared Redis server. The Docker Compose files have been updated to wire the password through consistently (#2602, #2603)
- **Optional skipping of the login page for single-provider instances** — On an instance with exactly one configured identity provider, the interim login page showing a single "Sign in with …" button can be skipped, sending users straight to the provider. This is behind a setting and off by default (#2720, #2728)

## Improvements

- **Register button hidden when registration is disabled** — The Register link previously stayed visible when `registration_disabled` was set, leading only to a page saying registration was unavailable. It is now hidden in the navbar, on the home page and in the login panel footer, with the explanation still shown to anyone reaching `/signup` directly. `registration_disabled` was also only ever a view-level check, so `POST /users` still created accounts; that is now enforced in the controller (#2720, #2728)
- **Relative links in workflow READMEs now resolve** — Relative links in a README.md used as a workflow description previously produced 404s. The markdown renderer now takes a relative root so those links resolve against the workflow (#642, #2719)
- **Shared throttle counters across instances** — `Rack::Attack` kept its throttle counters in an in-process memory store, so each app instance counted independently and the effective rate limit was multiplied by the number of web workers and containers. Counters now go to the shared Redis, under a `rack-attack` namespace, using the same connection as the cache, settings cache and sessions (#2689, #2694)
- **Alert when previewing an unfetched remote file** — Clicking a remote file in the Files tab of a Git-versioned workflow broke the preview iframe. The page now displays a clear alert explaining that the file is externally embedded and has not been fetched (#2708)
- **Thread-safety for `User.current_user` and `disable_authorization_checks`** — The current user and the authorization-check override are now held per-thread, avoiding cross-talk between concurrently served requests
- **Cross-record images blocked in rendered markdown** — The markdown renderer no longer renders images that reference another record's assets

## Bug Fixes

- **Text previews of non-UTF-8 and very large content** — Viewing an asset whose content blob is typed as text but is not valid UTF-8 raised `ArgumentError: invalid byte sequence in UTF-8` and made the show page impossible to render at all. Invalid bytes are now replaced when rendering, and very large text previews are truncated with an explanatory message (#2722)
- **Empty files for unfetched remote files in RO-Crates** — Remote files that had not been fetched were written into downloaded RO-Crates as empty files. They are now removed from the crate before it is zipped, and remote files carry a `localPath` property as the specification allows (#1829, #2701)
- **Invalid years causing a database error in the year filter** — Out-of-range years reaching `YearFilter` could trigger `Mysql2::Error: Incorrect DATE value` on some MySQL versions. Years are now restricted to the 1000–9999 range before the query is built, and a mixture of valid and invalid years no longer returns an empty set (#2715)

## Infrastructure & Dependencies

- **Rails upgraded to 8.1** — Rails moves from 7.2 to 8.1.3.1 ahead of 7.2 reaching end of life. Rack is upgraded to 3.x with its version pin removed, the deprecated `coffee-rails` gem is dropped, and `webdrivers` is replaced by `selenium-webdriver` 4.44 which manages drivers itself (#2612, #2613)
- **Framework defaults set to 8.1** — `config.load_defaults` moved from 7.2 to 8.1, adopting the eight settings in that delta, including `action_dispatch.strict_freshness` and the `escape_json_responses` default. Two of the held-back settings were already deprecated and would have broken on Rails 8.2. The global `Regexp.timeout` override was subsequently removed, reverting to the 1 second default that has applied since Rails 8.0 (#2730, #2732)
- **Solr upgraded from 8.11.4 to 9.10.1** — The Solr Docker image is upgraded across all Compose files and `script/start-docker-solr.sh`. The configuration is migrated to a Solr 9 compatible managed schema: Trie fields are replaced with Point fields with doc values, `LatLonType` with `LatLonPointSpatialField`, a `FlattenGraphFilterFactory` is added to the index-time analyser, and the broken spellcheck component and other incompatible elements are removed. **Existing installations will need to remove and re-create their local Solr installation, then reindex** (#2649, #2650)
- **Scheduled session trim task removed** — The daily `db:sessions:batch_trim` cron job and its rake task are gone, as the ActiveRecord session table it trimmed no longer exists under Redis sessions. Hosts will need to run `whenever --update-crontab` on deploy for the removed job to disappear from the crontab (#2687)
- **1.19 upgrade tasks cleaned up** — Upgrade tasks already present in the 1.18.0 release have been removed. No new tasks were added for 1.19, but the `sop_types` seed is retained as the seed data changed in 1.18.1, and the `update_rdf` task is kept as it is needed regularly (#2729)
- **`scrub_env!` monkey-patch removed from the test helper** — The workaround for rails/rails#54582 (marked won't fix upstream) has been removed. Tests that combined a multipart file-upload POST with later requests in the same test method are refactored to create versions and blobs via FactoryBot or to exercise each action in isolation, and new `little_file` content blob factories replace repeated inline file reads (#2614, #2632)
- **SPARQL example queries updated and tested** — `config/sparql_queries.yml` has been refreshed and a new integration test runs every example query against the seeded triple store, expecting results
- **supercronic bumped to v0.2.49** in the Docker container (#2657, #2723)
- **MySQL version bumped** in the Ansible install workflow
- Dependency updates: `nokogiri` 1.19.4, `rails-html-sanitizer` 1.7.1, `loofah` 2.25.2, `websocket-driver` 0.8.2, `net-imap` 0.6.4.1, `json` 2.21.2, `msgpack` 1.8.2, `sqlite3` 2.9.5, `faraday` 2.14.3 and `yard` 0.9.44

---
Note: `main` also carries the fixes released in 1.18.2 (page-scoped COPASI bundle, JavaScript minification, non-indexable sharing links, filter obfuscation, the Docker search fix and the anonymous experiment view fix). Those are documented in `RELEASE_NOTES_1.18.2.md` rather than repeated here.

---
Full list of changes: https://github.com/seek4science/seek/milestone/34?closed=1
