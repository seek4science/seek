# Be sure to restart your server when you modify this file.

SEEK::Application.configure do
  # Add new mime types for use in respond_to blocks:
  # Mime::Type.register "text/richtext", :rtf
  # Mime::Type.register_alias "text/html", :iphone

  Mime::Type.register_alias "image/svg+xml", :svg
  Mime::Type.register_alias "text/plain", :dot
  Mime::Type.register "application/rdf+xml", :rdf
  Mime::Type.register "application/vnd.wf4ever.robundle+zip", :ro

  # for publication export
  # http://filext.com/file-extension/ENW
  Mime::Type.register "application/x-endnote-refer", :enw
  # http://filext.com/file-extension/bibtex
  Mime::Type.register "application/x-bibtex", :bibtex
  # http://filext.com/file-extension/EMBL
  Mime::Type.register "chemical/x-embl-dl-nucleotide", :embl
end

