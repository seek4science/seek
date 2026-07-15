# Plan: Migrate from DelayedJob to Solid Queue (#2656)

Issue: [#2656 Investigate using SolidQueue for managing the job queue](https://github.com/seek4science/seek/issues/2656)
Branch: `solid-queue-2656`

## Goal

Replace `delayed_job_active_record` with `solid_queue` as the `ActiveJob` backend, without changing any job class behaviour beyond what's required for parity, and without regressing the multi-queue setup SEEK currently relies on.

## Current state (for reference)

- `config/application.rb:78` — `config.active_job.queue_adapter = :delayed_job`. All async work already goes through `ActiveJob` (`app/jobs/`, 44 job classes), not the DelayedJob API directly.
- `config/initializers/delayed_job_config.rb` — worker tuning (`max_attempts = 1`, `max_run_time = 1.day`, `sleep_delay`, `reserve_sql_strategy = :default_sql` to avoid deadlocks).
- `app/jobs/queue_names.rb` — 8 named queues (`default`, `mailers`, `authlookup`, `remotecontent`, `samples`, `indexing`, `templates`, `datafiles`).
- `lib/seek/workers.rb` — computes the *active* subset of those queues at boot from `Seek::Config` feature flags (e.g. `AUTH_LOOKUP` queue only runs if `Seek::Config.auth_lookup_enabled`), then daemonizes one single-threaded `delayed_job` worker process per active queue.
- `docker/start_workers.sh`, `script/check_worker_pids.sh`, `rake seek:workers:start/stop` — process management and Docker healthcheck, all delayed_job-specific (parse `tmp/pids/delayed_job.*.pid`).
- `config/schedule.rb` (via `whenever` gem) — cron-driven scheduling. Some entries just call `.perform_later`/`.queue_job` on a job (candidates for Solid Queue's recurring jobs), others run rake tasks, shell commands, or plain class methods that aren't jobs at all (`Galaxy::ToolMap.instance.refresh`, `kill-long-running-soffice.sh`, `sitemap:refresh`, `db:sessions:batch_trim`) — these can't move to Solid Queue and will stay on `whenever`/cron.
- `app/jobs/application_job.rb` — custom `queue_job`/`follow_on_job?`/duplicate-avoidance logic layered on top of `enqueue`, plus manual exception reporting via `Seek::Errors::ExceptionForwarder` (no automatic retries: `max_attempts = 1`).
- Test env uses `queue_adapter = :test`; unit tests optionally run against SQLite (`database.github.sqlite3.yml`) as well as MySQL.

## Key risks identified

1. **Concurrency model change**: DelayedJob workers are separate single-threaded OS processes; Solid Queue's default worker runs multiple jobs concurrently via threads in one process. Several job classes touch libraries not audited for thread-safety (Rugged/libgit2 via `Git::Repository`/`Git::Blob`/`Git::Tree`/`Git::Version`, RSolr/Sunspot, OpenBIS/LifeMonitor HTTP clients, image processing). Needs an explicit audit before increasing thread counts above 1 per queue.
2. **`config/schedule.rb` only partially migrates** — non-job scheduled tasks stay on `whenever`, so this is not a full replacement of the cron layer.
3. **Dynamic queue activation**: `Seek::Workers.active_queues` reads `Seek::Config` feature flags at boot. Solid Queue's `config/queue.yml` is static (ERB+YAML, evaluated once at supervisor boot), so replicating "only run a worker for enabled features" requires DB access at Solid Queue supervisor boot and a restart when a feature flag changes — same category of concern as the recent `settings_table_available?` fallback work.
4. **Retry semantics**: current `max_attempts = 1` (fail fast + manual exception report) must be deliberately replicated (`retry_on`/`discard_on`), otherwise jobs may start silently retrying (risk: duplicate emails).
5. **Cutover of in-flight jobs**: rows already in `delayed_jobs` don't automatically appear in Solid Queue's tables. Decision: rather than draining `delayed_jobs` to zero before cutover, existing rows will be **migrated** into the Solid Queue tables (re-enqueued preserving queue name, `run_at`/scheduled time, priority, and attempts where possible). This avoids a drain window but means `delayed_job_active_record` and the `delayed_jobs` table must stay in the app (gem + schema) until a later version, as a few queues may still hold or reference rows through the transition.
6. **Infra rewrite surface**: `lib/seek/workers.rb`, `docker/start_workers.sh`, `script/check_worker_pids.sh`, `rake seek:workers:*` are all delayed_job-specific and need rewriting against Solid Queue's process model (`bin/jobs`).

## Phased plan

### Phase 0 — Audit & decisions
- [ ] Audit job classes for thread-safety (Rugged/git jobs, HTTP clients, image/ImageMagick calls, Sunspot session use) to decide safe per-queue thread pool sizes.
- [ ] Decide: shared app database vs. separate `solid_queue` database (isolation vs. added `config/database*.yml` complexity across the three existing DB config files).
- [ ] Decide: replicate today's "one queue per active feature flag" topology 1:1, or consolidate (e.g. wildcard queue matching) as part of this migration.
- [ ] Confirm Rails/Ruby versions already satisfy Solid Queue's requirements (Gemfile currently pins Rails 8.1.3 — fine; note discrepancy with AGENTS.md which still says 7.2, worth a docs fix separately).

### Phase 1 — Add Solid Queue alongside DelayedJob (no cutover yet)
- [ ] Add `solid_queue` gem, run install generator, add migrations for the queue database(s).
- [ ] Write `config/queue.yml` mirroring `QueueNames`/`Seek::Workers.active_queues`, gated by `Seek::Config` where needed.
- [ ] Write `config/recurring.yml` for the subset of `config/schedule.rb` entries that are pure job enqueues (`PeriodicSubscriptionEmailJob`, `RegularMaintenanceJob`, `AuthLookupMaintenanceJob`, `LifeMonitorStatusJob`, `NewsFeedRefreshJob`, `ApplicationJob.queue_timed_jobs`). Leave non-job entries in `config/schedule.rb`/`whenever`.
- [ ] Reconcile retry/failure behaviour in `ApplicationJob` with Solid Queue equivalents (`retry_on`/`discard_on`, failed-execution inspection) to preserve current fail-fast + exception-forwarding semantics.

### Phase 2 — Local/dev verification
- [ ] Run full job-related test suite (unit + functional + integration) against `queue_adapter = :solid_queue` in a local/dev environment.
- [ ] Manually exercise representative jobs from each queue (mailers, indexing, datafiles, remotecontent, samples, templates, authlookup, default), including a Rugged/git-backed job, under real threaded concurrency.

### Phase 3 — Infra rework
- [ ] Replace `lib/seek/workers.rb`, `rake seek:workers:start/stop`, `docker/start_workers.sh` usage of `Delayed::Command` with `bin/jobs` (Solid Queue supervisor).
- [ ] Rewrite `script/check_worker_pids.sh` healthcheck for Solid Queue's process/PID model.
- [ ] Update `docker-compose.yml` `seek_workers` service accordingly.

### Phase 4 — Cutover
- [ ] Write a `migrate_delayed_jobs_to_solid_queue` rake task that reads all pending rows from `delayed_jobs` and re-enqueues equivalent jobs into Solid Queue (mapping queue, `run_at`, priority, attempts).
- [ ] Wire it into the existing upgrade-task mechanism in `lib/tasks/seek_upgrades.rake`, following the established pattern: add it to the `upgrade_version_tasks` list for this release, wrapped in `only_once('seek:migrate_delayed_jobs_to_solid_queue <version>')` (same pattern as `update_rdf`'s `only_once('seek:update_rdf 1.18.0')`) so it runs exactly once, driven by `ActivityLog`, the next time `rake seek:upgrade` is run — no separate manual step.
- [ ] Flip `config.active_job.queue_adapter` to `:solid_queue` in the same release as this upgrade task, so the migration always runs before Solid Queue starts picking up jobs.
- [ ] `delayed_job_active_record` gem, `delayed_jobs` table/schema, and `lib/seek/workers.rb`/old Docker scripts remain in the codebase (unused for new jobs) rather than being removed in this release — kept as a safety net and in case any straggling rows/tooling still reference them.

### Phase 5 — Cleanup (deferred to a later version)
- [ ] Once Solid Queue has been running in production for a full release cycle with no need to fall back, remove `delayed_job_active_record` gem, `config/initializers/delayed_job_config.rb`, `lib/seek/workers.rb`, old Docker scripts, and the `delayed_jobs` table.
- [ ] Update `AGENTS.md`/`CLAUDE.md` background-jobs section to describe Solid Queue instead of delayed_job.

## Open questions (need input before/at Phase 0)

- Shared vs. separate database for Solid Queue tables?
- Any hard requirement to keep MySQL *and* SQLite parity for the queue backend in test/dev, or is SQLite acceptable as test-only with reduced concurrency guarantees?
- Target thread pool sizes per queue, or start conservative (1 thread each, matching current behaviour) and tune later?
- What should the migration task do with `delayed_jobs` rows that are currently locked/failed/mid-attempt at the moment of cutover?

## Rollback plan

Keep `queue_adapter` a one-line config change through Phase 4. `delayed_job_active_record`, its tables, and the old worker scripts remain installed (not removed until Phase 5 in a later version), so if issues surface post-cutover the adapter can be flipped back to `:delayed_job` while investigating, without needing to reinstall anything.
