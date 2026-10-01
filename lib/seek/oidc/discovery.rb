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
      DISCOVERY_PATH = '.well-known/openid-configuration'.freeze

      def initialize(issuer)
        @issuer = issuer.to_s
      end

      # The provider's key set, in the form ruby-jwt's key finder asks for it.
      #
      # That finder asks again with invalidate: true when a token names a key the set does not
      # hold, which is how a rotated key gets picked up.
      def key_set(invalidate: false)
        refresh! if invalidate
        @key_set ||= parse(jwks_json)
      end

      private

      # A refetch for a key the set does not hold. Allowed at most once every REFRESH_COOLDOWN
      # across the whole deployment, so that tokens naming invented key ids cannot turn each
      # request into a request to the provider, and not attempted at all while the provider is
      # known to be down. Never fatal: when it does not happen the set stands as it is and the key
      # is simply not found, which is already how an unknown key id ends.
      def refresh!
        return if provider_unavailable? || !refresh_allowed?

        json = reaching_provider { fetch_jwks_json }
        Rails.cache.write(cache_key('jwks'), json, expires_in: JWKS_CACHE_TTL)
        @key_set = parse(json)
      rescue Error => e
        Rails.logger.info("Keeping the OpenID Connect key set already held: #{e.message}")
      end

      # A key set already in hand is used even while the provider is known to be down. It was
      # fetched while the provider was up and an outage does not make it wrong, so only fetching
      # is refused; refusing to use it as well would turn a moment's outage into a minute in which
      # every token is rejected.
      def jwks_json
        Rails.cache.fetch(cache_key('jwks'), expires_in: JWKS_CACHE_TTL) do
          raise Error, "the signing keys of '#{@issuer}' could not be fetched recently" if provider_unavailable?

          reaching_provider { fetch_jwks_json }
        end
      end

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

      # Writing with unless_exist is a single atomic operation - Redis SET NX - so this bounds
      # refreshes across every process, not merely within one.
      def refresh_allowed?
        Rails.cache.write(cache_key('jwks-refresh'), true,
                          expires_in: REFRESH_COOLDOWN, unless_exist: true)
      end

      # Read before being handed back to be cached for JWKS_CACHE_TTL, so that a response which is
      # not a key set is never stored, failing identically for half a day.
      def fetch_jwks_json
        body = BoundedFetch.get(jwks_uri)
        parse(body)
        body
      end

      # Only jwks_uri is taken from the discovery document, which is fetched over the same bounded
      # connection as everything else here. The library's own discovery goes through swd, whose
      # Faraday connection sets no timeouts at all: a provider that accepts a connection and then
      # never answers would hold the request thread for as long as it cared to, and since nothing
      # is raised the provider would never be marked unavailable either, so every later request
      # carrying a token would do the same until no thread was left.
      def jwks_uri
        Rails.cache.fetch(cache_key('jwks-uri'), expires_in: DISCOVERY_CACHE_TTL) do
          jwks_uri_from(BoundedFetch.get(discovery_uri))
        end
      end

      # The issuer is checked because the document says which provider it describes, and a key set
      # is only the right one to trust if it belongs to the issuer the tokens will name.
      def jwks_uri_from(body)
        document = ::JSON.parse(body)
        issued_by = document['issuer']
        raise Error, "#{discovery_uri} describes the issuer '#{issued_by}'" unless issued_by == @issuer

        document['jwks_uri'].presence || raise(Error, "#{discovery_uri} names no jwks_uri")
      rescue ::JSON::ParserError => e
        raise Error, "#{discovery_uri} is not JSON: #{e.message}"
      end

      # Built from the issuer as configured, scheme included, which is what the provider itself
      # publishes the document under.
      def discovery_uri
        "#{@issuer.chomp('/')}/#{DISCOVERY_PATH}"
      end

      # Built key by key. JWT::JWK.create_from raises for a key type ruby-jwt cannot represent -
      # anything but RSA, EC and oct - and building the set in one go would discard every usable
      # key alongside it. A provider publishing an EdDSA key next to its RSA ones is reason enough,
      # and the ones it cannot use would otherwise be fatal for as long as the set stayed cached.
      def parse(json)
        keys = published_keys(json).filter_map do |key|
          ::JWT::JWK.create_from(key)
        rescue ::JWT::JWKError => e
          Rails.logger.info("Ignoring a key published by '#{@issuer}': #{e.message}")
          nil
        end
        Rails.logger.warn("No usable signing key published by '#{@issuer}'") if keys.empty?

        ::JWT::JWK::Set.new(keys)
      end

      def published_keys(json)
        published = ::JSON.parse(json)
        keys = published['keys'] if published.is_a?(::Hash)
        raise Error, "the key set of '#{@issuer}' lists no keys" unless keys.is_a?(::Array)

        keys
      end

      # Keyed on the issuer rather than its host, so that a second provider added later needs no
      # change here.
      def cache_key(suffix)
        "seek:oidc:#{Digest::SHA256.hexdigest(@issuer)}:#{suffix}"
      end
    end
  end
end
