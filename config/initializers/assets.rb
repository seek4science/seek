# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.configure do
  config.assets.paths += Dir["#{Rails.root}/vendor/assets/rails-assets/*/*"]
end
Rails.application.config.assets.compile = true

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += [
    'DataTables-1.8.2/jquery.js',
    'DataTables-1.8.2/jquery.dataTables.js',
    'DataTables-1.8.2/jquery.dataTables.rowGrouping.js',
    'DataTables-1.8.2/Scroller.js',
    'jquery-1.5.1.min',
    'jquery.bxslider',
    'spreadsheet_explorer',
    'spreadsheet_explorer_plot',
    'pdfjs/compatibility',
    'pdfjs/debugger',
    'pdfjs/l10n',
    'pdfjs/pdf',
    'pdfjs/viewer',
    "swfobject",
    "cytoscape_web/index",
    "profile_project_selection",
    'projects',
    'scales.js',
    'flot/index.js',
    'project_folders',
    'single_page/index',
    'tablesorter/jquery-latest.js',
    'tablesorter/jquery.tablesorter.js',
    'multi_step_wizard.js',
    "prepended/*.css",
    "cytoscape_isa_graph.css",
    "data_tables.css",
    "datacite_doi.css",
    "pdfjs/viewer.css",
    "scales.css",
    "spreadsheet_explorer.css",
    "tablesorter/blue/tablesorter_blue.css",
    "yui/index.css",
    "appended/*.css",
    "publications",
    'controlled_vocabs.js'
]

