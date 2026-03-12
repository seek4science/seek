# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# FIXME: Use Seek::Config.session_store_timeout somehow
SEEK::Application.config.session_store(:active_record_store, key: '_seek_session',
                                       expire_after: 30.minutes, same_site: :lax)
