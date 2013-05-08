module SEEK
  class Application < Rails::Application
    config.autoload_paths += %W(#{Rails.root}/app/sweepers #{Rails.root}/app/reindexers #{Rails.root}/app/jobs)

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    # config.log_level = :info
    begin
      RAILS_DEFAULT_LOGGER = Logger.new("#{Rails.root}/log/#{RAILS_ENV}.log")
    rescue StandardError
      RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
      RAILS_DEFAULT_LOGGER.level = Logger::WARN
      RAILS_DEFAULT_LOGGER.warn(
          "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
              "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
      )
    end

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'UTC'

    # Use the database for sessions instead of the cookie-based default,
    # which shouldn't be used to store highly confidential information
    # (create the session table with "rake db:sessions:create")
    config.action_controller.session_store = :active_record_store

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
        :assets_creator_reindexer

  end
end