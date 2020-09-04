require_relative 'boot'

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module SEEK
  class Application < Rails::Application
    config.eager_load_paths << Rails.root.join('lib')

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    # config.log_level = :info
    #begin
    #  RAILS_DEFAULT_LOGGER = Logger.new("#{Rails.root}/log/#{Rails.env}.log")
    #rescue StandardError
    #  RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
    #  RAILS_DEFAULT_LOGGER.level = Logger::WARN
    #  RAILS_DEFAULT_LOGGER.warn(
    #      "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
    #          "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
    #  )
    #end

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'UTC'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password,"rack.request.form_vars"]

    # Activate observers that should always be running
    config.active_record.observers = :annotation_reindexer,
        :assay_reindexer,
        :assay_asset_reindexer,
        :measured_item_reindexer,
        :studied_factor_reindexer,
        :experimental_condition_reindexer,
        :mapping_reindexer,
        :mapping_link_reindexer,
        :compound_reindexer,
        :synonym_reindexer,
        :person_reindexer,
        :programme_reindexer,
        :assets_creator_reindexer

    config.middleware.use Rack::Deflater,
                          include: %w(text/html application/xml application/json text/css application/javascript)
    config.middleware.use Rack::Attack
    config.middleware.use I18n::JS::Middleware

    config.exceptions_app = self.routes

    config.active_support.escape_html_entities_in_json = true

    #uncomment and set the value if running under a suburi or use RAILS_RELATIVE_URL_ROOT
    #config.relative_url_root = '/seek'

    # The default cache timestamp format is "nsec", however timestamps in AR aren't stored with that precision
    # This can result in mis-matches of cache_keys depending on if the record is saved or not, for example:
    # openbis_endpoints/26-20170404142724000000000...
    # openbis_endpoints/26-20170404142724224014370...
    config.active_record.cache_timestamp_format = :usec

    config.action_mailer.deliver_later_queue_name = 'mailers'

    config.active_job.queue_adapter = :delayed_job

    config.active_record.sqlite3.represent_boolean_as_integer = true

  end
end
