# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

#Got an error 'can't dup NilClass' and the internet told me this should fix it
config.reload_plugins = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

config.middleware.use "Rack::Bug",
  :secret_key => "CaeTyLU8Spfo1PiXNZ4cANaWeO4Y3ptYFjVRLbPo34gbAkV4wNLTDH2hHT8YAKV"

config.cache_store = [:file_store, "#{RAILS_ROOT}/tmp/cache"]
