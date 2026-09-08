module Seek
  # Zeitwerk derives this constant from the directory name with String#camelize, so the spelling
  # OIDC depends on the acronym registered in config/initializers/inflections.rb; removing it
  # there breaks boot. The namespace must never be called Seek::OpenIDConnect, or unqualified
  # references to the gem of that name would resolve to this namespace instead.
  module OIDC
    # The signing keys of the OpenID Connect provider configured for this instance, found through
    # its discovery document and cached, so that verifying an access token needs no request to the
    # provider.
    class Discovery
      class Error < StandardError; end

      JWKS_CACHE_TTL = 12.hours
      DISCOVERY_CACHE_TTL = 1.hour
      REFRESH_COOLDOWN = 5.minutes
      PROVIDER_UNAVAILABLE_TTL = 1.minute
      MAX_JWKS_BYTES = 128.kilobytes
      OPEN_TIMEOUT = 2
      READ_TIMEOUT = 5

      def initialize(issuer)
        @issuer = issuer.to_s
      end

      # The provider's key set, in the form ruby-jwt's key finder asks for it.
      #
      # That finder asks again with invalidate: true when a token names a key the set does not
      # hold, which is how a rotated key gets picked up. The refetch is allowed at most once every
      # REFRESH_COOLDOWN across the whole deployment, so that tokens naming invented key ids
      # cannot turn each request into a request to the provider. When it is refused the set comes
      # back unchanged and the key is simply not found.
      def key_set(invalidate: false)
        raise Error, "the signing keys of '#{@issuer}' could not be fetched recently" if provider_unavailable?

        reaching_provider do
          refresh! if invalidate && refresh_allowed?
          @key_set ||= parse(jwks_json)
        end
      end

      private

      # Any failure to reach the provider is noted for PROVIDER_UNAVAILABLE_TTL before being
      # raised. Rails.cache.fetch does not cache exceptions, so without this an outage would cost
      # an attempt, and the full timeout, on every API request rather than one a minute.
      def reaching_provider
        yield
      rescue StandardError => e
        Rails.logger.error("OpenID Connect provider '#{@issuer}' unavailable: #{e.class}: #{e.message}")
        Rails.cache.write(cache_key('unavailable'), true, expires_in: PROVIDER_UNAVAILABLE_TTL)
        raise Error, "could not obtain the signing keys of '#{@issuer}'"
      end

      # Note that when the cache is unreachable this reports the provider as available, so keys are
      # fetched afresh for each request. That is the one place where the bound on requests to the
      # provider depends on the cache being up.
      def provider_unavailable?
        Rails.cache.read(cache_key('unavailable')).present?
      end

      def refresh!
        json = fetch_jwks_json
        Rails.cache.write(cache_key('jwks'), json, expires_in: JWKS_CACHE_TTL)
        @key_set = parse(json)
      end

      # Writing with unless_exist is a single atomic operation - Redis SET NX - so this bounds
      # refreshes across every process, not merely within one.
      def refresh_allowed?
        Rails.cache.write(cache_key('jwks-refresh'), true,
                          expires_in: REFRESH_COOLDOWN, unless_exist: true)
      end

      def jwks_json
        Rails.cache.fetch(cache_key('jwks'), expires_in: JWKS_CACHE_TTL) { fetch_jwks_json }
      end

      def fetch_jwks_json
        uri = jwks_uri
        body = http_client.get(uri).body.to_s
        raise Error, "the key set at #{uri} is larger than #{MAX_JWKS_BYTES} bytes" if body.bytesize > MAX_JWKS_BYTES

        body
      end

      # Only jwks_uri is taken from the discovery document. The response object's #jwks and
      # #jwk(kid) share one instance variable but store different things in it, so calling either
      # of them spoils the result of the other.
      def jwks_uri
        Rails.cache.fetch(cache_key('jwks-uri'), expires_in: DISCOVERY_CACHE_TTL) do
          ::OpenIDConnect::Discovery::Provider::Config.discover!(@issuer).jwks_uri
        end
      end

      def parse(json)
        ::JWT::JWK::Set.new(::JSON.parse(json))
      end

      # A connection of our own rather than OpenIDConnect.http_client, which imposes no timeouts.
      # Its configuration block is held in a class variable shared with the browser login flow, so
      # setting them there would change that too.
      def http_client
        ::Faraday.new do |faraday|
          faraday.options.open_timeout = OPEN_TIMEOUT
          faraday.options.timeout = READ_TIMEOUT
          faraday.response :raise_error
        end
      end

      # Keyed on the issuer rather than its host, so that a second provider added later needs no
      # change here.
      def cache_key(suffix)
        "seek:oidc:#{Digest::SHA256.hexdigest(@issuer)}:#{suffix}"
      end
    end
  end
end
