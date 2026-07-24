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

### 1. Weekly digest email has a coverage gap near month boundaries (minor correctness) — FIXED

`config/recurring.yml` scheduled `periodic_subscription_email_weekly` as
`0 0 1,8,15,22 * *` (day-of-month), while the job computes its window as `1.week.ago`
(`app/jobs/periodic_subscription_email_job.rb:7`). These didn't line up at month end:

- Day 22's run covers days 15–22.
- Next run is day 1 of the following month, covering only the previous ~7 days (day 24/25 on).
- So **activity on ~the 23rd–24th was never included in any weekly digest**, and days 29–31
  never triggered a run at all.

Correction to the original review note: this was **not** a regression introduced by the
migration. `whenever`'s `every 1.week` genuinely emits `0 0 1,8,15,22 * *` (verified by running
whenever 1.0.0's `Cron` class: `1.week` lands in its `1.day…1.month` bucket → `day_frequency 7`
→ `comma_separated_timing(7, 31, 1)` → `1,8,15,22`), so the migration faithfully reproduced the
long-standing — but buggy — schedule. The gap pre-dated this branch.

**Fixed** by switching the weekly schedule to `0 0 * * 0` (every Sunday), which tiles the fixed
`1.week.ago` window with no gap or overlap, and updating the `test/integration/recurring_test.rb`
assertion to match. Done as its own commit (a deliberate behaviour change to long-standing digest
timing), separate from the faithful-migration commits.

### 2. Command-based recurring tasks now serialize on one worker thread (low / design note)

All `command:`-only entries (`application_status_refresh` every minute, `queue_timed_jobs`
every 10 min, `clear_finished_jobs`, `galaxy_tool_map_refresh`, `bioschema_data_dump_generate`)
enqueue onto `solid_queue_recurring`, which `config/queue.yml` gives a single `threads: 1`
worker. Under whenever these ran as independent `rails runner` processes; now a slow one
blocks the others.

In particular `bioschema_data_dump_generate` (00:10 daily) can run for minutes and will
stall the every-minute `application_status_refresh` behind it, and `clear_finished_jobs`
deliberately `sleep`s 0.3s between batches on that same thread.

**Assessment: probably not a real problem, leaving as-is.** The only concrete effect is that
`application_status_refresh` (a ~0.14s status-cache refresh) can be delayed by a few minutes
once a day, overnight, while the dump runs — i.e. a few minutes of status-cache staleness at
night. Moving these to the default queue does *not* help: every queue is `threads: 1` (a hard
constraint until the process-global `User.current_user` / `$authorization_checks_disabled` are
made thread-local), so they'd still serialize, and would then contend with user-facing default
jobs and lose the isolation the dedicated `solid_queue_recurring` queue gives them. If a case
ever does need concurrency, the fix is a dedicated queue + worker for the heavy command (a
recurring entry's `queue:` option routes it), not a higher thread count and not the default
queue.

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

Solid and well-tested. The one substantive suggestion — the weekly-digest schedule (#1) — has
been fixed; the rest are notes.

## Not yet expanded (if a deeper pass is wanted)

- `db/migrate/20260715145804_create_solid_queue_tables.rb` full table/index definitions vs
  solid_queue 1.4.0's bundled `queue_schema.rb`.
- `Gemfile.lock` version pins for `solid_queue` / `mission_control-jobs`.
- Mission Control auth gating (`MissionControlJobsController`, `config/initializers/mission_control.rb`,
  the `mission_control_jobs_path` route helper resolving correctly).
