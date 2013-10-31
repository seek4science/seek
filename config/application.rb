require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module SEEK
  class Application < Rails::Application
    config.autoload_paths += %W(#{Rails.root}/app/sweepers #{Rails.root}/app/reindexers #{Rails.root}/app/jobs)

    #also include lib/** files
    config.autoload_paths += Dir["#{Rails.root}/lib/**/"]

    # Asset pipeline
    # Enable the asset pipeline
    config.assets.enabled = true
    # Version of your assets, change this if you want to expire all your assets
    #config.assets.version = '1.0'
    # Change the path that assets are served from
    # config.assets.prefix = "/assets"
    config.assets.js_compressor = :yui
    config.assets.css_compressor = :yui

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
                                  calendar_date_select/calendar_date_select.js
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
                                  pdfjs/compatibility.js
                                  pdfjs/debugger.js
                                  pdfjs/l10n.js
                                  pdfjs/pdf.js
                                  pdfjs/viewer.js
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
                                  local.css
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

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    # config.log_level = :info
    #begin
    #  RAILS_DEFAULT_LOGGER = Logger.new("#{Rails.root}/log/#{Rails.env}.log")
    #rescue StandardError
    #  RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
    #  RAILS_DEFAULT_LOGGER.level = Logger::WARN
    #  RAILS_DEFAULT_LOGGER.warn(
    #      "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
    #          "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
    #  )
    #end

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'UTC'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password,"rack.request.form_vars"]

    # Activate observers that should always be running
    config.active_record.observers = :annotation_reindexer,
        :assay_reindexer,
        :assay_asset_reindexer,
        :measured_item_reindexer,
        :studied_factor_reindexer,
        :experimental_condition_reindexer,
        :mapping_reindexer,
        :mapping_link_reindexer,
        :compound_reindexer,
        :synonym_reindexer,
        :person_reindexer,
        :assets_creator_reindexer

    config.action_view.sanitized_allowed_attributes = ['rel']

  end
end