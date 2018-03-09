# Be sure to restart your server when you modify this file.

SEEK::Application.configure do
  # Add new mime types for use in respond_to blocks:
  # Mime::Type.register "text/richtext", :rtf
  # Mime::Type.register_alias "text/html", :iphone

  Mime::Type.register_alias "image/svg+xml", :svg
  Mime::Type.register_alias "text/plain", :dot
  Mime::Type.register "application/rdf+xml", :rdf
  Mime::Type.register "application/vnd.wf4ever.robundle+zip", :ro

  api_mime_types = %W(
     application/vnd.api+json
     text/x-json
     application/json
  )
  #the space before 'version'  is important, if the user doesn't use space in his request header, it will not work unless we eliminate the space here
  api_mime_types.append("application/vnd.api+json; version=1")
  api_mime_types.append('application/vnd.api.v1+json')
  Mime::Type.unregister :json
  Mime::Type.register 'application/vnd.api+json', :json, api_mime_types

  # for publication export
  # http://filext.com/file-extension/ENW
  Mime::Type.register "application/x-endnote-refer", :enw
  # http://filext.com/file-extension/bibtex
  Mime::Type.register "application/x-bibtex", :bibtex
  # http://filext.com/file-extension/EMBL
  Mime::Type.register "chemical/x-embl-dl-nucleotide", :embl
end

