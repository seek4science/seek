require 'rest-client'
require 'open-uri'

module Seek
  module DownloadHandling
    class HTTPHandler

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
        file = Tempfile.new('remote-content')
        file.binmode # Strange encoding issues occur if this is not set

        Seek::DownloadHandling::HTTPStreamer.new(@url).stream do |chunk|
          file << chunk
        end

        file
      end

    end
  end
end
