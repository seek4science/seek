# Manual Testing Guide: Solid Queue (#2656)

Companion to `SOLID_QUEUE_MIGRATION_PLAN.md`. This is a walkthrough for manually exercising
Solid Queue on a local/dev checkout of this branch, both to verify it works and to build a
feel for how the pieces fit together before relying on it in production.

## How it works, in brief

- Jobs are still plain `ActiveJob` classes in `app/jobs/` — nothing about *how you enqueue a
  job* changed. `config/application.rb` now sets `config.active_job.queue_adapter = :solid_queue`,
  so `SomeJob.perform_later` writes a row to the `solid_queue_jobs` table (in the main app
  database — see `db/migrate/20260715145804_create_solid_queue_tables.rb`) instead of to
  `delayed_jobs`.
- Nothing processes that table unless a **supervisor** process is running. That's `bin/jobs`
  (Solid Queue's own CLI), which reads `config/queue.yml` and, for each configured queue,
  forks worker/dispatcher subprocesses that poll the DB and run due jobs. It also reads
  `config/recurring.yml` and runs a scheduler subprocess that enqueues jobs on a cron-like
  schedule (Solid Queue's equivalent of `whenever`/cron, but only for the subset of
  `config/schedule.rb` that's a pure job enqueue — see the plan doc for what didn't move).
- `config/queue.yml` mirrors SEEK's existing per-feature queues 1:1 (`default`, `mailers`,
  `authlookup`, `remotecontent`, `samples`, `indexing`, `templates`, `datafiles`), each with
  its own worker and deliberately just **1 thread**, gated by the same `Seek::Config` feature
  flags the old DelayedJob setup used. A queue whose feature is disabled gets no worker at all.
- `script/run_solid_queue.sh` is a thin wrapper around `bin/jobs` that restarts it if it dies,
  and is what's actually launched in Docker/deployment (`docker/start_workers.sh`,
  `docker/entrypoint.sh`). Locally you can just run `bin/jobs` directly and skip the wrapper.
- The admin UI (`/admin`) shows live state: a "Solid Queue supervisor" status
  panel (running/not running, PID) with a restart button, and a job-queue stats panel listing
  pending `SolidQueue::Job` rows and any failed ones.

## 1. Start the app and the worker supervisor

In one terminal:

```bash
bundle exec rails server
```

In a second terminal, start the Solid Queue supervisor:

```bash
bundle exec bin/jobs
```

You should see log output listing the dispatcher and one worker per enabled queue (the exact
set depends on which features are enabled in your dev DB — check `Seek::Config.solr_enabled`,
`samples_enabled`, etc. if a queue you expect is missing). Leave this running; it's your live
window into job processing for the rest of this guide.

## 2. Enqueue a job and watch it get picked up

From a third terminal, using `rails console` (or `rails runner`):

```ruby
RegularMaintenanceJob.perform_later
```

Watch the `bin/jobs` terminal — within its polling interval (0.1s for most queues, see
`config/queue.yml`) you should see it claim and run the job. Then confirm it's gone from the
pending table and no failure was recorded:

```ruby
SolidQueue::Job.where(class_name: 'RegularMaintenanceJob').order(created_at: :desc).first
# finished_at should be set
SolidQueue::Job.failed.count
# should still be 0
```

## 3. Exercise a job on each queue

Each entry below enqueues something real onto a different queue (see `app/jobs/queue_names.rb`
for the mapping). Pick a record that exists in your dev DB, or create one — these are meant to
be low-risk/idempotent operations. Run them from `rails console` while `bin/jobs` is running,
and watch the corresponding worker in the `bin/jobs` log pick each one up.

| Queue | Example |
|---|---|
| `default` | `RegularMaintenanceJob.perform_later` |
| `mailers` | Trigger any action that sends mail, e.g. `Person.first.send_notification_email` (or just `ActionMailer` `deliver_later` from a console) |
| `authlookup` | `AuthLookupUpdateQueue.enqueue(DataFile.first)` — queues the item *and* enqueues `AuthLookupUpdateJob` to process it (needs `Seek::Config.auth_lookup_enabled`) |
| `remotecontent` | Whatever job backs remote content caching (needs `Seek::Config.cache_remote_files`) |
| `samples` | An action that touches `Sample` linking/deletion (needs `Seek::Config.samples_enabled`) |
| `indexing` | `ReindexingQueue.enqueue(DataFile.first)` — same pattern as `authlookup`, queues the item and enqueues `ReindexingJob` (needs `Seek::Config.solr_enabled`) |
| `templates` | An ISA JSON template-related job (needs `Seek::Config.isa_json_compliance_enabled`) |
| `datafiles` | A job triggered by uploading/updating a `DataFile` (needs `Seek::Config.data_files_enabled`) |

Note `AuthLookupUpdateJob` and `ReindexingJob` are `BatchJob` subclasses (`app/jobs/batch_job.rb`)
— they don't take arguments directly via `perform_later`; they always drain whatever is
currently sitting in their backing queue table (`AuthLookupUpdateQueue`/`ReindexingQueue`).
That's why the examples above queue the item first and let `queue_job` (called internally by
`enqueue`) trigger the job, rather than calling `perform_later` directly.

If a queue's feature flag is off, `bin/jobs` won't have started a worker for it at all — enable
the flag (Admin UI or `Seek::Config.x_enabled = true` in console) and restart `bin/jobs` to
pick it up (see §5, this mirrors the "settings changed, restart workers" note already in the
admin UI).

## 4. Recurring jobs

`config/recurring.yml` only has entries for the `production` environment (deliberately — see
the comment in that file, to avoid subscription emails etc. firing on a dev machine). To see
one fire without waiting for its real cron schedule, temporarily add a `development` block, e.g.:

```yaml
development:
  news_feed_refresh_test:
    class: NewsFeedRefreshJob
    schedule: "* * * * *"   # every minute
```

Restart `bin/jobs`, wait a minute, and confirm in the console:

```ruby
SolidQueue::Job.where(class_name: 'NewsFeedRefreshJob').order(created_at: :desc).first
```

Revert the temporary edit afterwards — don't commit it.

To sanity-check the real production schedules parse correctly without running them:

```ruby
YAML.load(ERB.new(File.read('config/recurring.yml')).result)['production'].each do |name, cfg|
  puts "#{name}: #{Fugit.parse(cfg['schedule']).valid?}"
end
```

## 5. Admin UI

Log in as an admin and visit `/admin`.

- **Restart panel**: shows "Solid Queue supervisor — Running (Process ID: N)" while `bin/jobs`
  is up. Click **Restart background job workers** and confirm the PID changes (it signals the
  supervisor's pidfile, `tmp/pids/solid_queue_supervisor.pid`; `script/run_solid_queue.sh`'s
  restart loop brings it back up with a new PID — if you started `bin/jobs` directly rather than
  via the wrapper script, the button will just kill it with nothing to restart it, so for this
  specific check start the app via `script/run_solid_queue.sh` instead of plain `bin/jobs`).
- **Job queue stats** (Admin → Statistics, or wherever `_job_queue.html.erb` is rendered):
  lists pending `SolidQueue::Job` rows (queue, class, scheduled time) and a failed-job count
  with a "Clear failed jobs" button. To see a failed row, you need something that actually
  raises all the way out to Solid Queue — every real app job inherits from `ApplicationJob`,
  whose `rescue_from(Exception)` (`app/jobs/application_job.rb`) swallows the exception itself
  (reports it via `ExceptionForwarder`, logs it, and stops there) in every environment except
  test, so ordinary app jobs will never show up here even when they error. To demo the failure
  UI, use a throwaway job that skips `ApplicationJob` and inherits from `ActiveJob::Base`
  directly, from `rails console`:

  ```ruby
  class TmpAlwaysFailJob < ActiveJob::Base
    queue_as :default
    def perform
      raise "boom"
    end
  end
  TmpAlwaysFailJob.perform_later
  ```

  then refresh the stats page — you should see it listed as failed with the error visible, and
  the "Clear failed jobs" button should make it disappear.

## 6. Stopping / restarting semantics

Two different pidfiles, two different behaviours (see `script/run_solid_queue.sh`):

```bash
script/run_solid_queue.sh &          # start via the wrapper, like Docker/deployment does

# Restart in place (what the admin button and deploy "reload" do):
kill -TERM $(cat tmp/pids/solid_queue_supervisor.pid)
# -> bin/jobs exits, the wrapper's loop notices and starts a fresh one automatically

# Stop for good (what script/update-from-git.sh does before an upgrade):
kill -TERM $(cat tmp/pids/solid_queue_runner.pid)
# -> wrapper forwards the signal to bin/jobs, waits for it to exit, then exits itself, no restart
```

Also check the Docker healthcheck script works standalone:

```bash
script/check_worker_pids.sh
# "Solid Queue supervisor running (Process ID: N)." while up, exit 0
# "Solid Queue supervisor is not running." after a full stop, exit 1
```

## 7. Cross-database sanity check (optional)

The migration supports MySQL (default), SQLite, and Postgres. If you want to confirm Solid
Queue's tables/behaviour on a non-default adapter, point `DATABASE_URL` at a scratch SQLite or
Postgres database, `bundle exec rake db:schema:load`, and repeat step 2 against it. Not
necessary for routine testing — this was already verified adapter-by-adapter in Phase 2 of the
migration plan — just useful if you're touching queue-table-related code and want to double
check you haven't introduced an adapter-specific assumption.

## Useful console snippets

```ruby
# All pending jobs, oldest first
SolidQueue::Job.where(finished_at: nil).order(:created_at)

# Everything on one queue
SolidQueue::Job.where(queue_name: 'mailers')

# Failed jobs with their error
SolidQueue::Job.failed.includes(:failed_execution).map { |j| [j.class_name, j.failed_execution.error] }

# Live worker/dispatcher/scheduler processes (what ApplicationStatus#refresh counts)
SolidQueue::Process.where('last_heartbeat_at > ?', SolidQueue.process_alive_threshold.ago)

# Configured recurring tasks
SolidQueue::RecurringTask.all.map { |t| [t.key, t.schedule] }
```
