# Used by the admin "background job workers" status panel/restart button
# (app/views/admin/_restart_buttons.html.erb, AdminController#restart_job_workers)
# to find and signal the running supervisor process.
SolidQueue.supervisor_pidfile = Rails.root.join('tmp', 'pids', 'solid_queue_supervisor.pid')

# Solid Queue preserves finished jobs (preserve_finished_jobs defaults to true) so they remain
# visible in the admin/Mission Control dashboards. The clear_finished_jobs recurring task
# (config/recurring.yml) prunes anything finished longer ago than this - keep 14 days of history
# rather than the gem default of 1 day.
SolidQueue.clear_finished_jobs_after = 14.days
