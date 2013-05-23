# Be sure to restart your server when you modify this file.

SEEK::Application.configure do
  # Add new mime types for use in respond_to blocks:
  # Mime::Type.register "text/richtext", :rtf
  # Mime::Type.register_alias "text/html", :iphone

  Mime::Type.register_alias "image/svg+xml", :svg
  Mime::Type.register_alias "text/plain", :dot
  Mime::Type.register "application/rdf+xml", :rdf
  Mime::Type.register "application/x-endnote-refer", :enw
end

