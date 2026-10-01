module Seek
  module OIDC
    # A GET bounded in both time and size, for talking to an OpenID Connect provider, which is a
    # third party that cannot be relied on to answer quickly or briefly.
    class BoundedFetch
      class Error < StandardError; end

      MAX_RESPONSE_BYTES = 128.kilobytes
      OPEN_TIMEOUT = 2
      READ_TIMEOUT = 5

      def self.get(uri)
        new(uri).get
      end

      def initialize(uri)
        @uri = uri.to_s
      end

      # The limit is applied to the chunks as they arrive rather than to the finished body, so that
      # a response which does not stop is abandoned part way instead of being held in memory first.
      def get
        body = String.new(encoding: Encoding::BINARY)
        http_client.get(@uri) do |request|
          request.options.on_data = proc do |chunk, _overall_size, _env|
            body << chunk
            raise Error, "#{@uri} returned more than #{MAX_RESPONSE_BYTES} bytes" if body.bytesize > MAX_RESPONSE_BYTES
          end
        end
        body.force_encoding(Encoding::UTF_8)
      end

      private

      # A connection of our own rather than OpenIDConnect.http_client or swd's, neither of which
      # imposes any timeout. Their configuration is held in class variables shared with the browser
      # login flow, so setting them there would change that too.
      def http_client
        ::Faraday.new do |faraday|
          faraday.options.open_timeout = OPEN_TIMEOUT
          faraday.options.timeout = READ_TIMEOUT
          faraday.response :raise_error
        end
      end
    end
  end
end
