class Rack::Attack
  if Rails.env.production?
    throttle('logins/username', limit: 10, period: 5.minutes) do |req|
      if req.path == '/session' && req.post?
        req.params['login']
      end
    end

    throttle('logins/ip', limit: 30, period: 1.hour) do |req|
      if req.path == '/session' && req.post?
        req.ip
      end
    end
  end
end
