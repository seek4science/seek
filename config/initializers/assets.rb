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
    'spreadsheet_explorer',
    'pdfjs/compatibility',
    'pdfjs/debugger',
    'pdfjs/l10n',
    'pdfjs/pdf',
    'pdfjs/viewer.js',
    "pdfjs/viewer.css",
    "cytoscape_web/index",
    'projects',
    'flot/index.js',
    'project_folders',
    'select2.full.min',
    'select2.min.css',
    'select2.bootstrap.min.css',
    'single_page/index.js',
    'single_page/dynamic_table.js',
    'tablesorter/jquery-latest.js',
    'tablesorter/jquery.tablesorter.js',
    'multi_step_wizard.js',
    "prepended/*.css",
    "spreadsheet_explorer.css",
    'tablesorter/jquery.tablesorter.js',
    "tablesorter/blue/tablesorter_blue.css",
    "appended/*.css",
    "publications",
]

