SEEK::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  #This can be very useful in development when you have code that interacts directly with Rails.cache,
  #but caching may interfere with being able to see the results of code changes.
  config.cache_store = :memory_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  #omniauth enable testing
  OmniAuth.config.test_mode = true

  # Uncomment this to help find source of  "DEPRECATION WARNING: It looks like you are eager loading table(s) ..."
  # config.active_record.disable_implicit_join_references = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # TODO: Change this to: `:random` when tests are all passing
  config.active_support.test_order = :sorted

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = false

  # Uncomment this to raise exception on unpermitted params:
  # config.action_controller.action_on_unpermitted_parameters = :raise
end
