# Settings specified here will take precedence over those in config/environment.rb
SEEK::Application.configure do
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  #Got an error 'can't dup NilClass' and the internet told me this should fix it
  config.reload_plugins = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports
  config.consider_all_requests_local = true

  #disable caching
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.cache_store = [:file_store, "#{Rails.root}/tmp/cache"]

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

# Log the query plan for queries taking more than this (works
# with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.active_support.deprecation = :log
end



