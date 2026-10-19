require_relative 'redis_config'

module Seek
  # Builds the cache store holding Rack::Attack's throttle counters. Extracted from the initializer
  # so that integration tests can install exactly the store the app runs with, rather than a
  # near-copy that could drift from it.
  #
  # Loaded via require_relative from config/initializers/rack_attack.rb, so as with
  # Seek::RedisConfig this must not depend on Zeitwerk autoloading being available.
  module RackAttackStore
    NAMESPACE = 'rack-attack'.freeze

    def self.build
      ActiveSupport::Cache::RedisCacheStore.new(
        url: Seek::RedisConfig.url,
        namespace: NAMESPACE,
        # If Redis is unavailable the store returns nil rather than raising, so requests are allowed
        # through instead of erroring.
        error_handler: lambda { |method:, returning:, exception:|
          Rails.logger.warn("Rack::Attack Redis cache error in #{method} " \
                            "(returning #{returning.inspect}): #{exception.message}")
        }
      )
    end
  end
end
