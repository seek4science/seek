# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
Rails.configuration.after_initialize do
  SEEK::Application.config.session_store(:active_record_store,
                                         key: '_seek_session',
                                         expire_after: Seek::Config.session_store_timeout)
end