# Be sure to restart your server when you modify this file.

redis_host = ENV.fetch('REDIS_HOST', 'localhost')
redis_password = ENV.fetch('REDIS_PASSWORD', nil)
session_url =
  if redis_password.present?
    "redis://:#{CGI::escape(redis_password)}@#{redis_host}:6379/0/session"
  else
    "redis://#{redis_host}:6379/0/session"
  end

session_options = {
  servers: [session_url],
  expire_after: 30.minutes,
  key: '_seek_session',
  threadsafe: true,
  same_site: :lax,
  httponly: true
}

# Define the redis session store
SEEK::Application.config.session_store(:redis_store, **session_options)
