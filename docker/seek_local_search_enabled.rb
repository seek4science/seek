# Enables Solr search for the Docker image.
#
# This is set in two places on purpose. The `searchable ... if Seek::Config.solr_enabled`
# guards in the models are evaluated at class-load time, which in production (eager_load)
# happens *before* the main config defaults (config/initializers/seek_configuration.rb) run,
# since those are loaded from an after_initialize block. If solr_enabled is not already true
# at that point, nothing gets registered as searchable and search silently returns everything.
#
# before_eager_load runs after autoloading is set up but before the models are eager loaded,
# so set the default there to ensure the searchable definitions are registered.
Rails.application.config.before_eager_load do
  Seek::Config.default :solr_enabled, true
end

# The main defaults run later (in after_initialize) and reset solr_enabled to false, so
# re-assert it here afterwards so it also wins at runtime.
Rails.application.config.after_initialize do
  Seek::Config.default :solr_enabled, true
end
