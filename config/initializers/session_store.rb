# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# FIXME: Use Seek::Config.session_store_timeout somehow

session_url = "#{ENV.fetch('REDIS_URL', 'redis://localhost:6379')}/0/session"
domain_name = ENV.fetch('DOMAIN_NAME', 'localhost')

session_options = {
  servers: [session_url],
  expire_after: 30.minutes,
  key: '_seek_session',
  threadsafe: true,
  same_site: :lax,
  secure: Rails.env.production?,
  httponly: true
}

# Only set the domain constraint if FQDN is configured
session_options[:domain] = domain_name if domain_name != 'localhost'

# Define the redis session store
SEEK::Application.config.session_store(:redis_store, **session_options)
