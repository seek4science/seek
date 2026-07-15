# Used by the admin "background job workers" status panel/restart button
# (app/views/admin/_restart_buttons.html.erb, AdminController#restart_job_workers)
# to find and signal the running supervisor process.
SolidQueue.supervisor_pidfile = Rails.root.join('tmp', 'pids', 'solid_queue_supervisor.pid')
