module Seek
  module UrlValidation
    def valid_url?(url)
      uri = URI.parse(url)
      uri.absolute? && uri.scheme != 'urn'
    rescue URI::InvalidURIError
      false
    end
  end
end