# Settings specified here will take precedence over those in config/environment.rb
SEEK::Application.configure do
  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Specifies the header that your server uses for sending files
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  config.action_controller.perform_caching             = true
  config.action_controller.cache_store = [:file_store, "#{Rails.root}/tmp/cache"]
  config.cache_store = [:file_store, "#{Rails.root}/tmp/cache"]
  #config.action_view.cache_template_loading            = true


  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  #
  #
  config.active_support.deprecation = :notify
end

