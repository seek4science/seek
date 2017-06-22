module Seek
  module UrlValidation
    def valid_url?(url)
      URI.parse(url).absolute? rescue false
    end
  end
end