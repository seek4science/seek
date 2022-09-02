Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 4.megabytes)

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
