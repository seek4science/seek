module Seek
  module DownloadHandling
    ##
    # A class to handle streaming remote content over HTTP.
    # Monitors the number of bytes downloading and terminates
    #  if it exceeds a given limit.
    class HTTPStreamer
      REDIRECT_LIMIT = 10

      def initialize(url, options = {})
        @url = url
        @size_limit = options[:size_limit]
      end

      # yields a chunk of data to the given block
      def stream(&block)
        get_uri(URI(@url), 0, block)
      end

      private

      def get_uri(uri, redirect_count, block)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(Net::HTTP::Get.new(uri)) do |response|
            if response.code == '200'
              begin_stream(response, block)
            elsif response.code == '301' || response.code == '302'
              follow_redirect(uri, response, redirect_count, block)
            else
              fail BadResponseCodeException.new(response)
            end
          end
        end
      end

      def begin_stream(response, block)
        total_size = 0

        response.read_body do |chunk|
          total_size += chunk.size
          fail SizeLimitExceededException.new(total_size) if @size_limit && (total_size > @size_limit)
          block.call(chunk)
        end

        total_size
      end

      def follow_redirect(uri, response, redirect_count, block)
        if redirect_count >= REDIRECT_LIMIT
          fail RedirectLimitExceededException.new(redirect_count)
        else
          new_uri = URI(response.header['location'])
          new_uri = URI(uri) + new_uri if new_uri.relative?

          get_uri(new_uri, redirect_count + 1, block)
        end
      end
    end

    class RedirectLimitExceededException < Exception; end
    class SizeLimitExceededException < Exception; end
    class BadResponseCodeException < Exception; end
  end
end
