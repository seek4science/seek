# Mission Control - Jobs: a web dashboard for inspecting and managing Solid Queue jobs, mounted at
# /jobs in config/routes.rb.
#
# Gate it behind SEEK's own admin authentication (see MissionControlJobsController) and turn off the
# gem's default HTTP Basic auth, so access is controlled the same way as the rest of the admin area.
#
# These are set as module attributes rather than via `config.mission_control.jobs.*`: the engine
# copies that config hash into these same attributes in a `before_initialize` hook, which runs
# *before* config/initializers/*, so assigning the config object here would be too late to take
# effect. Assigning the module attributes directly (initializers run after before_initialize) is
# unambiguous.
MissionControl::Jobs.base_controller_class = 'MissionControlJobsController'
MissionControl::Jobs.http_basic_auth_enabled = false

# SEEK's own customisations to the dashboard (lib/seek/job_dashboard). Applied in to_prepare so
# they survive code reloading in development, where the gem's helper is unloaded and redefined.
Rails.application.config.to_prepare do
  MissionControl::Jobs::JobsHelper.prepend(Seek::JobDashboard::FinishedJobDuration)

  # AllConfiguredQueues has to sit in front of the gem's own SolidQueueExt, which the engine
  # prepends in a before_initialize hook - but only when the configured queue adapter is Solid
  # Queue. It isn't in the test environment, where JobsDashboardTestHelper wires up both in order
  # instead.
  if MissionControl::Jobs.adapters.include?(:solid_queue)
    ActiveJob::QueueAdapters::SolidQueueAdapter.prepend(Seek::JobDashboard::AllConfiguredQueues)
  end
end
