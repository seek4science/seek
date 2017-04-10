# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.compile = true

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += [
    "prepended/*.css",
    "cytoscape_isa_graph.css",
    "data_tables.css",
    "datacite_doi.css",
    "exhibit/styles/exhibit-scripted-bundle.css",
    "jquery-ui-1.8.14.custom.css",
    "jquery.ui.resizable.css",
    "lightbox.css",
    "pdfjs/viewer.css",
    "savage_beast/display.css",
    "scales/scales.css",
    "spreadsheet_explorer.css",
    "tablesorter/blue/tablesorter_blue.css",
    "yui/index.css",
    "appended/*.css"
]

