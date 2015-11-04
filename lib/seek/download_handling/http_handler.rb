require 'rest-client'

module Seek
  module DownloadHandling
    class HTTPHandler
      include Seek::UploadHandling::ContentInspection

      def initialize(url)
        @url = url
      end

      def info
        begin
          response = RestClient.head(@url)
          content_type = response.headers[:content_type]
          content_length = response.headers[:content_length].try(:to_i)
          file_name = determine_filename_from_disposition(response.headers[:content_disposition])
          code = response.code
        rescue RestClient::Exception => e
          code = e.http_code
          content_type = nil
          content_length = nil
        end

        file_name ||= determine_filename_from_url(@url)
        content_type ||= content_type_from_filename(file_name)

        {
            code: code,
            file_size: content_length,
            content_type: content_type,
            file_name: file_name
        }
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
