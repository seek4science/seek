require_relative 'boot'

require 'rails/all'
require_relative '../lib/rack/settings_cache'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module SEEK
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Force all environments to use the same logger level
    # Configuration for the application, engines, and railties goes here.
    # (by default production uses :info, the others :debug)
    #
    # config.log_level = :info
    # These settings can be overridden in specific environments using the files
    #begin
    # in config/environments, which are processed later.
    #  RAILS_DEFAULT_LOGGER = Logger.new("#{Rails.root}/log/#{Rails.env}.log")
    #
    #rescue StandardError
    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'UTC'

    config.eager_load_paths << Rails.root.join('lib')

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password,"rack.request.form_vars"]

    # Activate observers that should always be running
    config.active_record.observers = :annotation_reindexer,
        :assay_reindexer,
        :assay_asset_reindexer,
        :person_reindexer,
        :programme_reindexer,
        :assets_creator_reindexer

    config.middleware.use Rack::Deflater,
                          include: %w(text/html application/xml application/json text/css application/javascript)
    config.middleware.use Rack::Attack
    config.middleware.use I18n::JS::Middleware
    config.middleware.use Rack::SettingsCache

    config.exceptions_app = self.routes

    config.active_support.escape_html_entities_in_json = true

    #uncomment and set the value if running under a suburi or use RAILS_RELATIVE_URL_ROOT
    #config.relative_url_root = '/seek'

    # The default cache timestamp format is "nsec", however timestamps in AR aren't stored with that precision
    # This can result in mis-matches of cache_keys depending on if the record is saved or not, for example:
    # openbis_endpoints/26-20170404142724000000000...
    # openbis_endpoints/26-20170404142724224014370...
    config.active_record.cache_timestamp_format = :usec
    config.active_record.cache_versioning = false

    config.action_mailer.deliver_later_queue_name = 'mailers'

    config.active_job.queue_adapter = :delayed_job

    # Ignore translation overrides when testing
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'overrides', '**', '*.{rb,yml}')] unless Rails.env.test?

    config.active_record.belongs_to_required_by_default = false
    config.action_mailer.delivery_job = 'ActionMailer::MailDeliveryJob' # Can remove after updating defaults
    config.action_mailer.preview_path = "#{Rails.root}/test/mailers/previews" # For some reason it is looking in spec/ by default
  end
end
