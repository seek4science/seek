# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# FIXME: Use Seek::Config.session_store_timeout somehow
SEEK::Application.config.session_store(:redis_session_store,
                                       redis: {
                                         url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
                                         expire_after: 30.minutes,
                                         key_prefix: "session:",
                                         ssl_params: Rails.env.production? ? { verify_mode: OpenSSL::SSL::VERIFY_PEER } : nil
                                       },
                                       key: '_seek_session',
                                       same_site: :lax,
                                       secure: Rails.env.production?)
