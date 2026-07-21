# Alternative Plan: Migrate from DelayedJob to Sidekiq (#2656)

Issue: [#2656 Investigate using SolidQueue for managing the job queue](https://github.com/seek4science/seek/issues/2656)

This is an **alternative** to `SOLID_QUEUE_MIGRATION_PLAN.md`, kept for comparison. It describes what
migrating to Sidekiq would involve instead, and ends with an analysis (["Which starting point is
easier"](#which-starting-point-is-easier-delayedjob-vs-solid-queue)) of whether it would be easier to
migrate to Sidekiq **from the original DelayedJob** (i.e. from `main`) or **from the Solid Queue
version** now on the `solid-queue-2656` branch.

## Goal

Replace `delayed_job_active_record` with `sidekiq` as the `ActiveJob` backend, without changing any
job class behaviour beyond what's required for parity, and without regressing the multi-queue setup
SEEK currently relies on.

## Why this is mostly cheap — and where the real cost sits

The single most important fact (same as for Solid Queue): **all 45 job classes go through `ActiveJob`
already** (`config.active_job.queue_adapter`, `app/jobs/`), not any backend's native API. The only
non-ActiveJob async usage is a false positive (`sortable.min.js`). So the adapter itself is a one-line
swap for *any* backend. The migration cost is almost entirely in the surrounding infrastructure that
was built around a specific backend: worker process management, the admin UI, scheduling, and
retry/durability semantics. That surface is what the phases below (and the comparison) are really
about.

## What makes Sidekiq materially different from both DelayedJob and Solid Queue

These are the differences that drive the plan; each is grounded in this codebase, not generic.

1. **Storage: Redis, not the SQL database — and SEEK's current Redis is hostile to it.**
   DelayedJob and Solid Queue are both **SQL-backed** (they live in the primary MySQL database).
   Sidekiq stores its queues, retries and scheduled sets in **Redis**. SEEK already runs Redis
   (`redis ~> 5.4`, `redis-actionpack`), but it is configured explicitly for **caching**:
   `script/start-docker-redis.sh` starts it with `--maxmemory-policy allkeys-lru`, and
   `lib/seek/redis_config.rb` points the cache store, the settings cache **and** sessions all at the
   **same server, DB 0**. Sidekiq must **never** share a Redis with an `allkeys-lru` policy — under
   memory pressure Redis will silently evict Sidekiq's job keys, losing jobs. So Sidekiq requires a
   **dedicated Redis** (separate instance, or at minimum a separate server with `maxmemory-policy
   noeviction`), which is **new infrastructure** to provision, monitor, back up, and secure — exactly
   the thing the Solid Queue plan avoided by reusing the existing MySQL database (Phase 0 decision).

2. **Durability on crash.** DelayedJob and Solid Queue keep an in-flight job as a claimed **row**; if
   a worker is hard-killed the row is reclaimable, so the job is not lost. Open-source Sidekiq uses a
   non-reliable fetch (`BRPOP`) — a job popped off the queue but not yet finished when the process is
   `SIGKILL`ed (OOM, `docker kill`, node loss) is **lost**. The fix, `super_fetch` (reliable fetch),
   is **Sidekiq Pro/Enterprise only** (commercial). For a data-stewardship platform where jobs do
   things like persist uploaded sample data and update auth lookups, silent job loss is a real
   regression relative to today's DelayedJob behaviour.

3. **No numeric job priorities.** SEEK relies on numeric priorities: `ApplicationJob` sets
   `queue_with_priority 2`, and eight jobs override it (`queue_with_priority 1/3`, e.g.
   `LinkingSamplesUpdateJob`, `AuthLookupMaintenanceJob`), plus `config/recurring.yml`'s
   `news_feed_refresh` uses `priority: 3`. DelayedJob and Solid Queue both honour ActiveJob's numeric
   priority. **Sidekiq has no per-job priority** — ordering within a queue is strict FIFO, and
   priority is expressed only by listing queues in weighted or strict order at the process level. So
   every `queue_with_priority N` becomes a **silent no-op** under the Sidekiq adapter. Achieving
   parity means either accepting that loss or restructuring the priority intent into queue ordering —
   a behaviour change, not a config port.

4. **Licensing.** SEEK is BSD-3-clause. Sidekiq's open-source core is **LGPL-3.0**; the features that
   would close the gaps above (reliable fetch, batches, native periodic jobs, rate limiting) are in
   the **commercial** Pro/Enterprise tiers. Solid Queue is MIT and fully featured for free. Depending
   on an LGPL gem at runtime is legally workable for a BSD app, but the "pay for the parts that give
   parity with what we have now" shape is a genuine strategic cost, and unusual for an open-source
   academic project.

5. **Scheduling needs a third-party gem.** Solid Queue has **native** recurring jobs
   (`config/recurring.yml`, already built on this branch). Sidekiq's open-source core has **no**
   periodic scheduler; you add `sidekiq-cron` (community gem) or `sidekiq-scheduler`. (Native periodic
   jobs are a Sidekiq Enterprise feature.) This is another dependency to adopt, and its schedule
   format differs from both `whenever`/cron and `recurring.yml`.

6. **What Sidekiq gives back.** In fairness: a mature, batteries-included **Web UI**
   (`Sidekiq::Web`, mountable Rack app) showing queues, retries, scheduled, dead set, and live
   processes — far more than SEEK's hand-rolled admin panels; excellent throughput; and a very
   well-trodden operational story. These are real benefits — they're just weighed against items 1–5.

## Concurrency: the same blocker as Solid Queue, but it wastes Sidekiq's main advantage

The Solid Queue Phase 0 audit found two pieces of **process-global mutable state** that are only safe
today because each DelayedJob worker is a separate single-threaded OS process:

- `User.current_user` — a `cattr_accessor` (`app/models/user.rb`), set via `User.with_current_user`
  in `OpenbisSyncJob`, `FairDataStationImportJob`, `FairDataStationUpdateJob`, `SampleDataPersistJob`,
  `UnzipDataFilePersistJob`.
- `$authorization_checks_disabled` — a plain Ruby global (`lib/extensions/object.rb`), toggled by
  `disable_authorization_checks`, used in `LinkingSamplesUpdateJob`, `RemoteGitContentFetchingJob`,
  `SamplesBatchDeleteJob`, `Set/RemoveSubscriptionsForItemJob`, `LifeMonitorStatusJob`.

This finding is **backend-agnostic** — it's about SEEK's job code, not the queue — so it applies
identically to Sidekiq. But Sidekiq's entire value proposition is **high in-process thread
concurrency** (default 5–10 threads per process). To be safe without fixing these globals, Sidekiq
would have to run **`concurrency: 1`** (one thread) per process and rely on **separate processes** per
queue for parallelism — which throws away the very thing Sidekiq is best at and lands roughly where
DelayedJob already is (one single-threaded process per queue), only now with a Redis dependency bolted
on. Solid Queue is in the same 1-thread-per-queue posture on this branch, but it isn't giving up a
headline feature to be there. **Properly thread-localising these globals (`Concurrent::ThreadLocalVar`
/ `ActiveSupport::CurrentAttributes`) is the prerequisite that would let Sidekiq actually pay off**,
and it is not started.

## Dynamic queue activation

`Seek::Workers.active_queues` (on `main`) / `config/queue.yml` (Solid Queue branch) both derive the
*active* subset of the 8 named queues from `Seek::Config` feature flags at boot (e.g. the `authlookup`
queue only runs if `auth_lookup_enabled`). Sidekiq's process is told which queues to service via
`-q queue` flags or `config/sidekiq.yml`. Replicating "only run a worker for enabled features"
requires generating that queue list from `Seek::Config` at process start — the same category of
DB-at-boot concern noted for Solid Queue, solvable the same way (an ERB `sidekiq.yml` or a wrapper
that builds the `-q` flags), but it does have to be redone for Sidekiq's process model.

## Phased plan (Sidekiq)

### Phase 0 — Audit & decisions
- [ ] **Thread-safety** — reuse the Solid Queue Phase 0 audit result verbatim; it's backend-agnostic.
      Decision: run Sidekiq at `concurrency: 1` initially (matching current effective serialism),
      with parallelism via one process per active queue, until `User.current_user` /
      `$authorization_checks_disabled` are made thread-local. Flag that this negates Sidekiq's main
      benefit (see above) — so the audit's follow-up work is effectively a **precondition** for
      Sidekiq being worthwhile, in a way it wasn't for Solid Queue.
- [ ] **Redis topology** — decide on a **dedicated Redis** (or dedicated logical instance with
      `noeviction`) for Sidekiq, separate from the cache/session Redis, since the existing one is
      `allkeys-lru`. Provision, secure (password via `REDIS_PASSWORD` pattern already in
      `redis_config.rb`), and add to every deployment (Docker compose files, k8s, bare-metal).
- [ ] **Priority parity** — decide how to handle the loss of numeric `queue_with_priority`: either
      accept it, or express the three priority tiers as ordered/weighted queues. Requires touching the
      8 jobs that set a non-default priority.
- [ ] **Durability** — decide whether open-source Sidekiq's possible job loss on hard crash is
      acceptable, or whether Sidekiq Pro (`super_fetch`) is required. This is a licensing/procurement
      decision, not just a technical one.
- [ ] **Licensing sign-off** — confirm LGPL-3.0 core is acceptable for a BSD project, and whether any
      Pro/Enterprise features (reliability, native cron) will be purchased.

### Phase 1 — Add Sidekiq alongside DelayedJob (no cutover)
- [ ] Add `sidekiq` and a scheduler gem (`sidekiq-cron`) to the `Gemfile`.
- [ ] `config/initializers/sidekiq.rb` — point `Sidekiq.configure_server`/`configure_client` at the
      **dedicated** Redis URL (extend `Seek::RedisConfig` with a separate `sidekiq_url`, not DB 0 of
      the cache Redis). Set server concurrency to 1 per Phase 0.
- [ ] `config/sidekiq.yml` — queue list gated by `Seek::Config` flags (ERB, mirroring `queue.yml`'s
      approach on the Solid Queue branch), replicating the 1:1 per-feature topology.
- [ ] Port the six job-enqueue schedule entries into `sidekiq-cron` job definitions (from the actual
      `bundle exec whenever` output, exactly as the Solid Queue branch did for `recurring.yml`). Note
      `sidekiq-cron` handles only ActiveJob/worker classes — the `command:`-style plain-Ruby entries
      that `recurring.yml` supports (`Galaxy::ToolMap.instance.refresh`,
      `ApplicationStatus.instance.refresh`, `Seek::BioSchema::DataDump.generate_dumps`,
      `clear_finished_jobs`) would each need wrapping in a small job class, or left on `whenever`/cron.
- [ ] Retry/failure behaviour — **no code change needed, same reasoning as Solid Queue**:
      `ApplicationJob`'s `rescue_from(Exception)` swallows exceptions inside `perform_now` before the
      adapter ever sees them, so Sidekiq's retry set stays empty and its default 25-retry behaviour
      never triggers. (Worth a test to confirm, since Sidekiq's retry is otherwise much more
      aggressive than DelayedJob's `max_attempts = 1`.)

### Phase 2 — Local/dev verification
- [ ] Stand up the dedicated Redis locally; verify Sidekiq boots, services every gated queue, and
      drains a job enqueued onto each of the 8 queues plus a real `Git::Repository`/Rugged job (the
      same smoke test the Solid Queue Phase 2 used).
- [ ] Confirm `sidekiq-cron` schedules load and fire, matching the ported cron times.
- [ ] Run `test/unit/jobs/**` and the job-triggering functional slice unmodified to confirm no
      regression from adding the gem (test env stays on `:test` adapter, same as the Solid Queue plan).

### Phase 3 — Infra rework
- [ ] Replace the worker process model: `sidekiq` is its own long-running process (typically managed
      by systemd/foreman/Docker), so `script/run_solid_queue.sh` (or, from `main`,
      `lib/seek/workers.rb` + `rake seek:workers:*`) is replaced with a Sidekiq launcher; pidfile and
      restart handling reworked around Sidekiq's signals (`TSTP`/`TERM` for quiet/stop).
- [ ] `docker/start_workers.sh`, `docker/entrypoint.sh`, `script/check_worker_pids.sh` (healthcheck),
      and the deployment scripts (`script/update-from-git.sh`, `script/mini-update-from-git.sh`)
      repointed at Sidekiq. Docker compose files gain the dedicated Redis service.
- [ ] Admin UI: mount `Sidekiq::Web` (big win) **or** repoint the existing custom panels
      (`app/views/admin/stats/_job_queue.html.erb`, `_restart_buttons.html.erb`,
      `ApplicationStatus#refresh`) at Sidekiq's API (`Sidekiq::Queue`, `Sidekiq::Stats`,
      `Sidekiq::ProcessSet`, `Sidekiq::RetrySet`). Recommended: mount `Sidekiq::Web` behind the admin
      auth and drop the hand-rolled panels.

### Phase 4 — Cutover
- [ ] Flip `config.active_job.queue_adapter` to `:sidekiq`. Sidekiq starts from an empty queue.

### Phase 5 — Migrate historical rows
- [ ] Same shape as the Solid Queue plan: a one-off upgrade task re-enqueuing leftover `delayed_jobs`
      rows into Sidekiq. Simpler in one respect (re-enqueue via ActiveJob), but note the source rows
      are in SQL and the destination is Redis, so it's a cross-store move.

### Phase 6 — Cleanup
- [ ] Remove `delayed_job_active_record`, its initializer and table; update `AGENTS.md`/`CLAUDE.md`.

## Rollback plan

Same one-line-adapter-flip strategy as the Solid Queue plan (keep `delayed_job_active_record` and its
table installed through Phase 5). **Extra caveat unique to Sidekiq**: rollback doesn't remove the
dedicated Redis dependency once deployments have provisioned it, and any jobs that were only ever in
Redis (not SQL) don't exist in `delayed_jobs` to fall back to.

---

## Which starting point is easier: DelayedJob vs Solid Queue?

**Short answer: starting from the Solid Queue branch (`solid-queue-2656`) is easier than starting from
the original DelayedJob on `main` — but only modestly, and less so than the equivalent gap would be for
most backend swaps, because Solid Queue and Sidekiq differ in the one dimension (SQL vs Redis) that the
Solid Queue work can't pre-pay.**

### Where the Solid Queue branch is already ahead (helps a Sidekiq migration)

Everything the Solid Queue migration did that is **backend-agnostic** is reusable as-is, and would
otherwise have to be redone from scratch against DelayedJob:

- **The thread-safety audit** (Phase 0) — the `User.current_user` / `$authorization_checks_disabled`
  finding and its mitigation are about SEEK's job code, not the queue. Reusable verbatim. This is the
  single most valuable piece of prior work and it carries over completely.
- **Scheduling already decomposed.** On `main`, job scheduling is tangled into `config/schedule.rb`
  (`whenever`) mixed with rake tasks and shell commands. The Solid Queue branch already did the hard
  part: separating the job-enqueue entries out (into `recurring.yml`), deriving exact cron times from
  real `whenever` output, and leaving only genuine rake/shell tasks on cron. Porting a **clean,
  already-separated** list of six schedule entries into `sidekiq-cron` is far less error-prone than
  re-untangling `schedule.rb` from scratch — and the branch already fixed two subtle scheduling bugs
  (double-scheduling, and the offset applying to hour-frequency jobs) that a from-`main` effort would
  risk reintroducing.
- **Admin UI already generalised off DelayedJob.** `main`'s admin panels read `Delayed::Job` and
  worker pidfiles directly. The branch already rewrote them around a generic "current backend" shape
  (`SolidQueue::Job`, supervisor status, `ApplicationStatus#refresh` as a DB-backed process count).
  Repointing *that* at Sidekiq's API — or better, replacing it wholesale with `Sidekiq::Web` — is less
  work than starting from the `Delayed::Job`-specific version, and the "what state do we surface"
  question is already answered.
- **Retry/failure semantics already proven adapter-agnostic.** The branch empirically established that
  `ApplicationJob`'s `rescue_from(Exception)` swallows errors before the adapter sees them. That
  finding — and the conclusion that no `retry_on`/`discard_on` is needed — transfers directly to
  Sidekiq (and is *more* reassuring there, since Sidekiq's default retry is far more aggressive than
  DelayedJob's `max_attempts = 1`).
- **Worker infra already rewritten once.** `lib/seek/workers.rb`, the Docker scripts, the healthcheck
  and the deploy scripts were already lifted off DelayedJob's one-process-per-queue-via-`daemons`
  model onto a supervisor model. The *concepts* (feature-gated queue list, pidfile, restart button,
  healthcheck) are now cleanly identified and would be repointed at Sidekiq rather than rediscovered
  in DelayedJob-specific code.

### Where Solid Queue → Sidekiq is genuinely harder than DelayedJob → Sidekiq

This is the honest counterweight, and it's why the advantage is only "modest":

- **The SQL→Redis jump has to happen regardless, and the branch can't pre-pay it.** Both DelayedJob
  and Solid Queue are SQL-backed; Sidekiq is Redis-backed. None of the SQL-oriented work on the branch
  (the `solid_queue_*` migration, the shared-database decision, the schema-ordering fix) helps a
  Sidekiq migration — and some of it becomes **extra teardown**: the branch added 11 `solid_queue_*`
  tables and a migration that a Sidekiq migration would ultimately have to remove. From `main` there's
  nothing to tear down. So for the *storage* dimension specifically, `main` is a marginally cleaner
  starting point.
- **Two backends' worth of infra to unwind.** Going Solid Queue → Sidekiq means undoing
  Solid-Queue-specific artifacts (`config/queue.yml`, `config/recurring.yml`, `bin/jobs` /
  `run_solid_queue.sh`, `config/initializers/solid_queue.rb`, the `solid_queue_supervisor_pid` plumbing
  in `lib/seek/util.rb`) *and* building Sidekiq's. From `main` you unwind DelayedJob's and build
  Sidekiq's — one teardown, not "teardown of the thing we just built."

### Net assessment

| Dimension | From DelayedJob (`main`) | From Solid Queue (branch) |
|---|---|---|
| Thread-safety audit | redo from scratch | **reuse verbatim** |
| Schedule decomposition | untangle `schedule.rb` from scratch | **reuse clean split** |
| Admin UI | port off `Delayed::Job` specifics | **repoint generic shape / drop for Sidekiq::Web** |
| Retry semantics | rediscover | **already proven adapter-agnostic** |
| Worker infra concepts | rediscover in DJ code | **already identified, just repoint** |
| Storage model (SQL→Redis) | one build | one build **+ teardown of solid_queue tables** |
| Backend-specific teardown | DelayedJob only | Solid Queue **and** DelayedJob artifacts |

The **backend-agnostic** work (audit, scheduling decomposition, admin generalisation, retry proof,
infra concepts) dominates the effort and is **all already done** on the branch, so the branch wins.
The **storage** and **teardown** dimensions favour `main`, but they're the smaller share. On balance:
**start from the Solid Queue branch.** The reusable analysis and the already-untangled scheduling are
worth more than the cost of removing the `solid_queue_*` tables.

### The bigger point

The reason the gap between the two starting points is only "modest" is the same reason the whole
comparison is a bit academic: **because SEEK put everything behind `ActiveJob` years ago, the backend
is genuinely swappable, and most of the migration cost is in the surrounding infrastructure rather than
the jobs.** That cost is now paid once, generically, on the branch. Given that, the decision between
Solid Queue and Sidekiq should turn less on migration effort and more on the standing trade-offs above
— chiefly: **Sidekiq adds a Redis dependency SEEK's current cache Redis can't satisfy, loses numeric
priorities, needs commercial licensing for crash-durability, and only pays off once the global-state
concurrency blocker is fixed — whereas Solid Queue reuses the existing MySQL database, is MIT, honours
priorities, is crash-durable by construction, and is already working on the branch.** On this codebase,
those standing costs point away from Sidekiq regardless of which starting point you measure from.
