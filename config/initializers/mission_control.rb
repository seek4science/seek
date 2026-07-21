# Mission Control - Jobs (experimental, mission-control branch): a web dashboard for inspecting and
# managing Solid Queue jobs, mounted at /jobs in config/routes.rb.
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
