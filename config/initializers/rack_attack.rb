require_relative '../../lib/seek/redis_config'

# Throttle counts are kept in Redis rather than in-process memory so that they are shared across
# all app instances (web workers, multiple containers). With a memory store each instance counted
# separately, so the effective limit was multiplied by the number of instances.
#
# Tests use an in-memory store to avoid depending on a running Redis server.
Rack::Attack.cache.store = if Rails.env.test?
                             ActiveSupport::Cache::MemoryStore.new(size: 4.megabytes)
                           else
                             ActiveSupport::Cache::RedisCacheStore.new(
                               url: Seek::RedisConfig.url,
                               namespace: 'rack-attack',
                               # If Redis is unavailable the store returns nil rather than raising,
                               # so requests are allowed through instead of erroring.
                               error_handler: lambda { |method:, returning:, exception:|
                                 Rails.logger.warn("Rack::Attack Redis cache error in #{method} " \
                                                   "(returning #{returning.inspect}): #{exception.message}")
                               }
                             )
                           end

if Rails.env.production?
  Rack::Attack.throttle('logins/username', limit: 10, period: 5.minutes) do |req|
    if req.path == '/session' && req.post?
      req.params['login']
    end
  end

  Rack::Attack.throttle('logins/ip', limit: 30, period: 1.hour) do |req|
    if req.path == '/session' && req.post?
      req.ip
    end
  end
end
