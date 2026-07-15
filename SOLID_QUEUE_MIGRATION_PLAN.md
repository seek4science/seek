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
- Test env uses `queue_adapter = :test`; unit tests optionally run against SQLite (`database.github.sqlite3.yml`) as well as MySQL. The `pg` gem is also already in the `Gemfile`, so Postgres is a supported adapter alongside `mysql2` and `sqlite3`.
- Admin UI surfaces delayed_job internals directly: `app/views/admin/_restart_buttons.html.erb` shows expected vs. running worker processes (`Seek::Workers.active_queues.count`, `Seek::Util.delayed_job_pids`) and a "Restart background job workers" button (`restart_delayed_job_admin_path` → `rake seek:workers:restart`); `app/views/admin/stats/_job_queue.html.erb` lists `Delayed::Job` rows (priority, queue, attempts, run/locked/failed times, handler, last error) with a "Clear failed jobs" button (`AdminController#clear_failed_jobs` → `Delayed::Job.where('failed_at IS NOT NULL').destroy_all`).

## Key risks identified

1. **Concurrency model change**: DelayedJob workers are separate single-threaded OS processes; Solid Queue's default worker runs multiple jobs concurrently via threads in one process. **Phase 0 audit result (see below)**: the real risk isn't Rugged/git, HTTP clients, or Sunspot (all confirmed safe — fresh instances per call, or already thread-local), it's two pieces of **process-global mutable state** that were only safe under DelayedJob because each worker was a separate OS process:
   - `User.current_user` is a `cattr_accessor` (`app/models/user.rb:64`, a true class variable), set via `User.with_current_user` in `OpenbisSyncJob`, `FairDataStationImportJob`, `FairDataStationUpdateJob`, `SampleDataPersistJob`, `UnzipDataFilePersistJob`. Two such jobs running concurrently on different threads can clobber each other's current user (affects authorization, `contributor`, activity logging, and `ExceptionForwarder`'s default user).
   - `$authorization_checks_disabled` is a plain Ruby global (`lib/extensions/object.rb:4-9`), toggled by `disable_authorization_checks`, used in `LinkingSamplesUpdateJob`, `RemoteGitContentFetchingJob`, `SamplesBatchDeleteJob`, `Set/RemoveSubscriptionsForItemJob`, `LifeMonitorStatusJob`. Concurrent jobs can re-enable/disable authorization checks mid-flight for one another.

   Note both globals are already shared across Puma's 5 web-server threads (`config/puma.rb`) today, so this is a pre-existing latent bug class — Solid Queue just newly exposes it to job execution too, at higher likelihood given jobs hold these flags for longer stretches than a web request. **Mitigation for this migration: keep 1 thread per queue initially (matching current single-worker-per-queue behaviour), so no two jobs from the same or different queues execute in the same process concurrently.** Making these genuinely thread-safe (e.g. `Concurrent::ThreadLocalVar`/`RequestStore`) is worth doing but is a separate piece of work, not a blocker for this migration as long as concurrency stays effectively serial.
   - Secondary, lower-probability finding: `Git::Repository#git_base` correctly memoizes a fresh `Rugged::Repository` per AR instance (not shared), but two *different* jobs concurrently operating on the *same underlying git repo id* on separate threads (e.g. `RemoteGitFetchJob` and `RemoteGitContentFetchingJob` for the same repo) each open their own `Rugged::Repository` for the same on-disk path — worth keeping in mind if queue concurrency is increased later, though not currently known to be triggered by any existing code path.
2. **`config/schedule.rb` only partially migrates** — non-job scheduled tasks stay on `whenever`, so this is not a full replacement of the cron layer.
3. **Dynamic queue activation**: `Seek::Workers.active_queues` reads `Seek::Config` feature flags at boot. Solid Queue's `config/queue.yml` is static (ERB+YAML, evaluated once at supervisor boot), so replicating "only run a worker for enabled features" requires DB access at Solid Queue supervisor boot and a restart when a feature flag changes — same category of concern as the recent `settings_table_available?` fallback work.
4. **Retry semantics**: current `max_attempts = 1` (fail fast + manual exception report) must be deliberately replicated (`retry_on`/`discard_on`), otherwise jobs may start silently retrying (risk: duplicate emails).
5. **Cutover of in-flight jobs**: rows already in `delayed_jobs` don't automatically appear in Solid Queue's tables. Decision: cutover (flipping the adapter and deploying) is **decoupled** from migrating those rows — the adapter flip happens first, with Solid Queue simply starting from an empty queue, and migrating the pre-existing `delayed_jobs` rows into Solid Queue's tables is handled as a separate, later step (see Phase 5). This means there's a window, potentially spanning a release or more, where any rows still sitting in `delayed_jobs` at cutover time are not being processed by anything. `delayed_job_active_record` and the `delayed_jobs` table must stay in the app (gem + schema) until well after that migration has run.
6. **Infra rewrite surface**: `lib/seek/workers.rb`, `docker/start_workers.sh`, `script/check_worker_pids.sh`, `rake seek:workers:*` are all delayed_job-specific and need rewriting against Solid Queue's process model (`bin/jobs`).
7. **Admin UI is delayed_job-specific**: the worker status panel and job queue stats page query `Delayed::Job`/`Seek::Workers`/PID files directly. Since `delayed_job_active_record` and its tables remain installed through the transition (per point 5), these pages won't error, but once Solid Queue is live they'll show stale/empty data (no running processes, no queued jobs) rather than the real state — needs updating to show Solid Queue's processes and job/queue stats instead, not just left as-is.

## Phased plan

### Phase 0 — Audit & decisions
- [x] Audit job classes for thread-safety. Result: no issues found with Rugged/git, HTTP clients, Sunspot, or image processing (all use fresh instances per call or are already thread-local). The real finding is two process-global mutable state points (`User.current_user`, `$authorization_checks_disabled`) — see risk #1 above for detail and mitigation (1 thread per queue for this migration; making these properly thread-local is separate follow-up work).
- [x] Database: Solid Queue tables will live in the **shared** app database for now, not a separate database — no changes needed to `config/database.yml`'s single-database structure at this stage. A dedicated queue database can be revisited later if isolation becomes necessary.
- [x] Must support all three database adapters SEEK already supports: **MySQL** (`mysql2`, primary), **SQLite** (`sqlite3`, test/dev), and **Postgres** (`pg`, already in the `Gemfile`) — Solid Queue supports all three, so this constrains testing/verification (Phase 2) to cover all three, but doesn't rule anything out.
- [ ] Decide: replicate today's "one queue per active feature flag" topology 1:1, or consolidate (e.g. wildcard queue matching) as part of this migration.
- [x] Confirm Rails/Ruby versions already satisfy Solid Queue's requirements: Ruby `3.3.10` (`.ruby-version`), Rails `8.1.3` (`Gemfile.lock`) — both comfortably above Solid Queue's minimums (Rails 7.1+). `solid_queue` is not yet in `Gemfile.lock`, so it needs to be added explicitly in Phase 1 (Rails 8 ships it as the *default* for new apps, but SEEK's existing app doesn't have it wired up yet). Separately noted: `AGENTS.md` still describes the app as "Rails 7.2" — worth a docs fix, but unrelated to this migration.

### Phase 1 — Add Solid Queue alongside DelayedJob (no cutover yet)
- [ ] Add `solid_queue` gem, run install generator, add migrations for the queue tables in the shared database.
- [ ] Write `config/queue.yml` mirroring `QueueNames`/`Seek::Workers.active_queues`, gated by `Seek::Config` where needed. Per the Phase 0 thread-safety audit, set **1 thread per queue** for now (matching current single-worker-per-queue behaviour) — do not increase until `User.current_user`/`$authorization_checks_disabled` are made properly thread-local.
- [ ] Write `config/recurring.yml` for the subset of `config/schedule.rb` entries that are pure job enqueues (`PeriodicSubscriptionEmailJob`, `RegularMaintenanceJob`, `AuthLookupMaintenanceJob`, `LifeMonitorStatusJob`, `NewsFeedRefreshJob`, `ApplicationJob.queue_timed_jobs`). Leave non-job entries in `config/schedule.rb`/`whenever`.
- [ ] Reconcile retry/failure behaviour in `ApplicationJob` with Solid Queue equivalents (`retry_on`/`discard_on`, failed-execution inspection) to preserve current fail-fast + exception-forwarding semantics.

### Phase 2 — Local/dev verification
- [ ] Run full job-related test suite (unit + functional + integration) against `queue_adapter = :solid_queue` in a local/dev environment, across all three supported database adapters (MySQL, Postgres, SQLite).
- [ ] Manually exercise representative jobs from each queue (mailers, indexing, datafiles, remotecontent, samples, templates, authlookup, default), including a Rugged/git-backed job, under real threaded concurrency.

### Phase 3 — Infra rework
- [ ] Replace `lib/seek/workers.rb`, `rake seek:workers:start/stop`, `docker/start_workers.sh` usage of `Delayed::Command` with `bin/jobs` (Solid Queue supervisor).
- [ ] Rewrite `script/check_worker_pids.sh` healthcheck for Solid Queue's process/PID model.
- [ ] Update `docker-compose.yml` `seek_workers` service accordingly.
- [ ] Update admin pages to reflect Solid Queue instead of DelayedJob:
  - `app/views/admin/_restart_buttons.html.erb` — worker/process status panel and restart button (`AdminController#restart_delayed_job`) need to report Solid Queue's processes rather than `Seek::Workers.active_queues`/`Seek::Util.delayed_job_pids`.
  - `app/views/admin/stats/_job_queue.html.erb` — job queue stats table and "Clear failed jobs" action (`AdminController#clear_failed_jobs`) need to query Solid Queue's tables (e.g. `SolidQueue::Job`/`FailedExecution`) instead of `Delayed::Job`.

### Phase 4 — Cutover (deploy Solid Queue with an empty queue)
- [ ] Flip `config.active_job.queue_adapter` to `:solid_queue` and deploy. No migration task is required for this step — Solid Queue simply starts from an empty queue and handles everything enqueued from that point on.
- [ ] `delayed_jobs` is assumed to be empty by the time this phase happens — no monitoring, alerting, or manual checking of the old queue is needed between Phase 4 and Phase 5. If that assumption ever turns out to be wrong for a given deployment, Phase 5's migration task (which reads whatever remains) still covers it.
- [ ] Verify in production: recurring jobs (`config/recurring.yml`) firing correctly, each queue (mailers, indexing, datafiles, remotecontent, samples, templates, authlookup, default) processing new jobs, admin pages (Phase 3) showing real Solid Queue state.
- [ ] `delayed_job_active_record` gem, `delayed_jobs` table/schema, and `lib/seek/workers.rb`/old Docker scripts remain in the codebase (unused for new jobs going forward) — kept both as a rollback safety net and because the pre-existing rows still need Phase 5 to run.

### Phase 5 — Migrate historical `delayed_jobs` rows (later, separate release)
- [ ] Write a `migrate_delayed_jobs_to_solid_queue` rake task that reads all remaining rows from `delayed_jobs` (left over from before the Phase 4 cutover) and re-enqueues equivalent jobs into Solid Queue (mapping queue, `run_at`, priority, attempts). Rows that are locked (`locked_at`/`locked_by` set) are requeued as normal — i.e. effectively unlocked and migrated like any other pending row. Rows that are already failed (`failed_at` set) are deleted rather than migrated, not re-enqueued into Solid Queue.
- [ ] Wire it into the existing upgrade-task mechanism in `lib/tasks/seek_upgrades.rake`, following the established pattern: add it to the `upgrade_version_tasks` list for the release it ships in, wrapped in `only_once('seek:migrate_delayed_jobs_to_solid_queue <version>')` (same pattern as `update_rdf`'s `only_once('seek:update_rdf 1.18.0')`) so it runs exactly once, driven by `ActivityLog`, the next time `rake seek:upgrade` is run. Because this can land in a later release than Phase 4, no code changes to the adapter are needed at this point — it's purely a data migration.
- [ ] After this runs (and has been confirmed to have picked up everything), `delayed_jobs` no longer needs to be checked/read by anything — clears the way for Phase 6.

### Phase 6 — Cleanup (deferred to a later version still)
- [ ] Once Solid Queue has been running in production for a full release cycle with no need to fall back, and Phase 5's migration has run, remove `delayed_job_active_record` gem, `config/initializers/delayed_job_config.rb`, `lib/seek/workers.rb`, old Docker scripts, and the `delayed_jobs` table.
- [ ] Update `AGENTS.md`/`CLAUDE.md` background-jobs section to describe Solid Queue instead of delayed_job.

## Open questions

- Target thread pool sizes per queue — not something to decide up front; determined by the outcome of the Phase 0 thread-safety audit (start conservative, i.e. 1 thread per queue matching current behaviour, for anything the audit doesn't clear for higher concurrency).

## Rollback plan

Keep `queue_adapter` a one-line config change through Phase 5. `delayed_job_active_record`, its tables, and the old worker scripts remain installed (not removed until Phase 6 in a later version), so if issues surface after Phase 4 the adapter can be flipped back to `:delayed_job` while investigating, without needing to reinstall anything. Since Phase 4 and Phase 5 are decoupled, a rollback after Phase 4 but before Phase 5 simply resumes delayed_job workers against the (still-intact) `delayed_jobs` table plus whatever accumulated there in the meantime.
