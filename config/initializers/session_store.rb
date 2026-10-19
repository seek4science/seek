# Be sure to restart your server when you modify this file.

require_relative '../../lib/seek/redis_config'

# The session namespace lives on the same DB as the cache (Seek::RedisConfig.url), under the
# /session path, so cache and sessions share one authenticated connection URL.
session_url = "#{Seek::RedisConfig.url}/session"

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
