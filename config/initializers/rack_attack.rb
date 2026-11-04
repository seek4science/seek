require_relative '../../lib/seek/rack_attack_store'

# Throttle counts are kept in Redis so that all app instances (web workers, multiple containers)
# share one count and a limit applies across the deployment as a whole. An in-process store would
# count per instance, multiplying the effective limit by the number of instances.
#
# Unit and functional tests use an in-memory store, so they neither need a Redis server nor leave
# counters behind in one. Integration tests run against the Redis store this builds - see
# Seek::RackAttackStore and test/test_helper.rb.
Rack::Attack.cache.store = if Rails.env.test?
                             ActiveSupport::Cache::MemoryStore.new(size: 4.megabytes)
                           else
                             Seek::RackAttackStore.build
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
