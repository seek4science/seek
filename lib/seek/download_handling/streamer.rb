module Seek
  module DownloadHandling
    ##
    # A class to handle streaming remote content over HTTP.
    # Monitors the number of bytes downloading and terminates
    #  if it exceeds a given limit.
    class Streamer

      REDIRECT_LIMIT = 10

      def initialize(url)
        @url = url
      end

      # yields a chunk of data to the given block
      def stream(&block)
        get_uri(URI(@url), &block)
      end
\
      private

      def get_uri(uri, redirect_count = 0, &block)
        max_size = Seek::Config.hard_max_cachable_size
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(Net::HTTP::Get.new(uri)) do |res|
            if res.code == '200'
              total_size = 0
              res.read_body do |chunk|
                total_size += chunk.size
                raise SizeLimitExceededException.new(total_size) if total_size > max_size
                block.call(chunk)
              end
              total_size
            elsif res.code == '301' || res.code == '302'
              if redirect_count >= REDIRECT_LIMIT
                raise RedirectLimitExceededException.new(redirect_count)
              else
                get_uri(URI(res.header['location']), redirect_count+1, &block)
              end
            else
              raise BadResponseCodeException.new(res)
            end
          end
        end
      end

    end

    class RedirectLimitExceededException < Exception; end
    class SizeLimitExceededException < Exception; end
    class BadResponseCodeException < Exception; end
  end
end
