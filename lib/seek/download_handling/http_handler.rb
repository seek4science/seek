require 'rest-client'

module Seek
  module DownloadHandling
    class HTTPHandler
      include Seek::UploadHandling::ContentInspection

      attr_reader :url

      def initialize(url)
        @url = url
      end

      def info
        content_type = nil
        content_length = nil
        begin
          response = RestClient.head(url)
          if is_slideshare_url?
            content_type = 'text/html'
          else
            content_type = response.headers[:content_type]
          end
          content_length = response.headers[:content_length].try(:to_i)
          file_name = determine_filename_from_disposition(response.headers[:content_disposition])
          code = response.code
      rescue RestClient::Exception => e
        code = e.http_code
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        code = 404
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

        Seek::DownloadHandling::HTTPStreamer.new(url, size_limit: Seek::Config.hard_max_cachable_size).stream do |chunk|
          file << chunk
        end

        file
      end

      private

      # if it is a slideshare url, which starts with www.slideshare.net, and is made up of 2 parts (params ignored)
      # i.e http://www.slideshare.new/<org>/<slidetitle>
      #
      # this is a quick fix to get around slideshare not always giving a content type of text/html, and instead sometimes giving application/xml
      def is_slideshare_url?
        renderer = Seek::Renderers::SlideshareRenderer.new(nil)
        renderer.is_slideshare_url?(url)
      end
    end
  end
end
