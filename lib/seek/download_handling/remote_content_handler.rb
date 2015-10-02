require 'rest-client'
require 'open-uri'

module Seek
  module DownloadHandling
    class RemoteContentHandler

      def initialize(url)
        @url = url
      end

      def info
        begin
          response = RestClient.head(@url)
          content_type = response.headers[:content_type]
          content_length = response.headers[:content_length].try(:to_i)
          code = response.code
        rescue RestClient::Exception => e
          code = e.http_code
          content_type = nil
          content_length = nil
        end
        { content_type: content_type,
          content_length: content_length,
          code: code }
      end

      def fetch
        if info[:content_length] && info[:content_length] < 100000000000000 # TODO: implement Seek::Config.max_cachable_size
          open(@url)
        end
      end

    end
  end
end