# Settings specified here will take precedence over those in config/environment.rb
SEEK::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.action_controller.cache_store = [:file_store, "#{Rails.root}/tmp/cache"]
  config.cache_store = [:file_store, "#{Rails.root}/tmp/cache"]

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true
  config.assets.precompile += %w(
                                  admin.js
                                  assays.js
                                  associate_events.js
                                  attribution.js
                                  batch_upload.js
                                  bioportal_form_complete.js
                                  biosample.js
                                  detect_browser.js
                                  fancy_multiselect.js
                                  folds.js
                                  isa_graph.js
                                  jws/index.js
                                  link_adder.js
                                  models.js
                                  people.js
                                  project_folders.js
                                  projects.js
                                  publishing.js
                                  resource.js
                                  scales/scales.js
                                  sharing.js
                                  spreadsheet_explorer.js
                                  spreadsheet_explorer_plot.js
                                  strain.js
                                  studied_factor.js
                                  calendar_date_select/calendar_date_select
                                  cytoscape.js-2.0.2/index.js
                                  cytoscape_web/index.js
                                  DataTables-1.8.2/index.js
                                  dropMenu.js
                                  dygraph-combined.js
                                  flot/index.js
                                  jquery-1.5.1.min.js
                                  jquery-ui-1.8.14.custom.min.js
                                  jscrollpane/index.js
                                  parseuri.js
                                  pdfjs/index.js
                                  slider.js
                                  sound.js
                                  swfobject.js
                                  tabber-minimized.js
                                  yui/index.js
                                  zoom/lightbox.js
                                  asset_report.css
                                  batch_upload.css
                                  biosamples.css
                                  full_scroll_table.css
                                  homepage.css
                                  isa_graph.css
                                  jws/index.css
                                  match_making.css
                                  project_folders.css
                                  publishing.css
                                  scaffold.css
                                  scales/scales.css
                                  settings.css
                                  spreadsheet_explorer.css
                                  calendar_date_select/default.css
                                  cytoscape.js-2.0.2/index.css
                                  data_tables.css
                                  jquery-ui-1.8.14.custom.css
                                  jscrollpane/jquery.jscrollpane.css
                                  lightbox.css
                                  pdfjs/viewer.css
                                  yui/index.css
                                )

  #The X-Sendfile header is a directive to the web server to ignore the response from the application,
  #and instead serve a specified file from disk
  #config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

end

