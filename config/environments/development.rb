SEEK::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  #This can be very useful in development when you have code that interacts directly with Rails.cache,
  #but caching may interfere with being able to see the results of code changes.
  #config.cache_store = :null_store
  config.cache_store = :file_store, "#{Rails.root}/tmp/cache/dev-cache"

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true


  config.public_file_server.enabled = true

  I18n.enforce_available_locales = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # config.log_level = :warn
  # disable SQL logs from active record by TZ
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = 1

  # Don't log asset requests
  config.assets.quiet = true
end
