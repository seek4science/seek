module Seek
  module OIDC
    # A GET bounded in time and size, and refused over cleartext, for talking to an OpenID Connect
    # provider: a third party that cannot be relied on to answer quickly or briefly, and whose
    # keys decide who may act as any linked user.
    class BoundedFetch
      class Error < StandardError; end

      MAX_RESPONSE_BYTES = 128.kilobytes
      OPEN_TIMEOUT = 2
      READ_TIMEOUT = 5
      INSECURE_ENV_VAR = 'OIDC_INSECURE_DISCOVERY'.freeze

      def self.get(uri)
        new(uri).get
      end

      # A provider is no more trustworthy than the connection its keys arrive over: anybody able to
      # answer in its place can publish a key set of their own and so mint a token for any linked
      # user. Cleartext is refused rather than trusted, and the exception for a provider on a
      # developer's own machine has to be asked for and is ignored in production.
      def self.insecure_allowed?
        !Rails.env.production? && ENV[INSECURE_ENV_VAR] == '1'
      end

      def initialize(uri)
        @uri = uri.to_s
      end

      # The limit is applied to the chunks as they arrive rather than to the finished body, so that
      # a response which does not stop is abandoned part way instead of being held in memory first.
      def get
        raise Error, "refusing to fetch #{@uri} over anything but https" unless secure?

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

      def secure?
        ::URI.parse(@uri).scheme == 'https' || self.class.insecure_allowed?
      rescue ::URI::InvalidURIError
        false
      end

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
