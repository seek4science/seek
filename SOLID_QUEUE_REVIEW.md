# Review: DelayedJob → Solid Queue migration (`solid-queue-2656`)

_Review date: 2026-07-22 · Branch reviewed against merge-base with `main` (`3bbf03ef62`)_

## Summary

Large, carefully-executed migration from DelayedJob to Solid Queue. Worker topology,
recurring schedules, the admin panels, the docker/deploy scripts, and a one-off
historical-job migrator are all covered, with genuinely good test coverage
(`test/integration/recurring_test.rb`, `test/unit/delayed_job_migrator_test.rb`,
updated admin/status tests).

Load-bearing Solid Queue API assumptions were verified against the installed gem
(solid_queue **1.4.0**):

- `SolidQueue::Job.failed` / `.finished` scopes exist (`retryable.rb`, `executable.rb`).
- `SolidQueue::Job.clear_finished_in_batches` exists (`clearable.rb`).
- `SolidQueue.process_alive_threshold`, `.supervisor_pidfile`, `.clear_finished_jobs_after` exist.
- Worker `metadata['queues']` is a comma-joined string (`worker.rb`), `Process#metadata` is JSON-stored.
- **Crucially:** `SolidQueue::Job.create!` fires `after_create :prepare_for_execution`
  (`executable.rb`), so the migrator's direct-`create!` approach really does enqueue jobs
  for execution (dispatches to ready/scheduled). This is the thing most likely to be a silent
  bug, and it is correct.

No leftover references to `Daemons`, `Seek::Workers`, `delayed_job_pids`, `RUN_PERIOD`,
`restart_delayed_job`, `seek:workers`, or `whenever` remain.

## Findings

### 1. Weekly digest email has a coverage gap near month boundaries (minor correctness)

`config/recurring.yml` schedules `periodic_subscription_email_weekly` as
`0 0 1,8,15,22 * *` (day-of-month), while the job computes its window as `1.week.ago`
(`app/jobs/periodic_subscription_email_job.rb:7`). These don't line up at month end:

- Day 22's run covers days 15–22.
- Next run is day 1 of the following month, covering only the previous ~7 days (day 24/25 on).
- So **activity on ~the 23rd–24th is never included in any weekly digest**, and days 29–31
  never trigger a run at all.

The old `every 1.week` schedule produced contiguous 7-day windows with no gap. The
`recurring.yml` header comment claims this "matches the cron schedule whenever produced" —
for the day/month-frequency jobs that's not quite accurate. If the intent is to preserve
weekly behaviour, `0 0 * * 0` (Sunday) matches the fixed `1.week.ago` window cleanly.

**Action:** confirm the `1,8,15,22` choice was deliberate rather than an assumed equivalence.
Note: `test/integration/recurring_test.rb` asserts `0 0 1,8,15,22 * *`, so any change means
updating that test too.

### 2. Command-based recurring tasks now serialize on one worker thread (low / design note)

All `command:`-only entries (`application_status_refresh` every minute, `queue_timed_jobs`
every 10 min, `clear_finished_jobs`, `galaxy_tool_map_refresh`, `bioschema_data_dump_generate`)
enqueue onto `solid_queue_recurring`, which `config/queue.yml` gives a single `threads: 1`
worker. Under whenever these ran as independent `rails runner` processes; now a slow one
blocks the others.

In particular `bioschema_data_dump_generate` (00:10 daily) can run for minutes and will
stall the every-minute `application_status_refresh` behind it, and `clear_finished_jobs`
deliberately `sleep`s 0.3s between batches on that same thread. Functionally fine, but a
real change in concurrency behaviour — the heavier commands may eventually deserve their own
queue/worker.

### 3. Minor edge cases (informational)

- `Seek::Util.solid_queue_supervisor_pid` treats `Process.kill(0, pid)` raising `Errno::EPERM`
  as "not running" (`lib/seek/util.rb`). If the supervisor is ever owned by a different user
  the status panel reports it down. Fine for a standard single-user deploy.
- `restart_job_workers` runs `kill -TERM $(cat #{pidfile})` (`app/controllers/admin_controller.rb`).
  If the pidfile is absent, `kill` gets no argument and Terrapin surfaces a non-zero exit as a
  flash error to the admin — acceptable failure mode. Also: the restart only self-heals under
  `script/run_solid_queue.sh` (docker/prod); in a bare `bin/jobs` dev session the button stops
  workers without restarting them.
- `app/views/admin/_restart_buttons.html.erb` renders each worker's `metadata['queues']` (a
  comma-joined string) as one `<li>`. Correct only because the topology is one queue per worker —
  if queues are ever consolidated, a list item will read `q1,q2`.

## Confirmed NOT problems

- The soffice reaper being docker-only in `docker/seek.crontab` is correct — `schedule.rb`
  already guarded it with `if Seek::Docker.using_docker?`, so no non-docker regression.
- Dropping `db:sessions:batch_trim` is consistent with sessions living in Redis (`allkeys-lru`) now.
- The migrator preserves serialized arguments so dangling GlobalIDs don't abort the migration
  (test: "migrates a job whose argument record has since been deleted without raising"), folds
  `attempts` into `executions`, and 0-priority handling works despite the `||` chain (0 is truthy).
- `SolidQueue::Job.create!` enqueues via the `after_create` callback (verified above).

## Overall

Solid and well-tested. The one substantive suggestion is to double-check the weekly-digest
schedule (#1); the rest are notes.

## Not yet expanded (if a deeper pass is wanted)

- `db/migrate/20260715145804_create_solid_queue_tables.rb` full table/index definitions vs
  solid_queue 1.4.0's bundled `queue_schema.rb`.
- `Gemfile.lock` version pins for `solid_queue` / `mission_control-jobs`.
- Mission Control auth gating (`MissionControlJobsController`, `config/initializers/mission_control.rb`,
  the `mission_control_jobs_path` route helper resolving correctly).
