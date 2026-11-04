require 'cgi'

module Seek
  # Single source of truth for the Redis connection URL, built from REDIS_HOST, (optionally)
  # REDIS_PASSWORD and (optionally) REDIS_TLS. The cache store, the settings cache, the session store
  # and the Rack::Attack throttle counters all go through here, so they connect to the same server and
  # all authenticate when a password is set. Anything else needing Redis should use this too rather
  # than reading the environment directly, otherwise a password-protected Redis works for some of them
  # and not others.
  #
  # Loaded via require_relative from config/environments/*.rb, which are evaluated before Zeitwerk
  # autoloading is available, so this must not reference autoloaded constants or ActiveSupport core
  # extensions (hence plain Ruby rather than String#present?).
  module RedisConfig
    DEFAULT_HOST = 'localhost'.freeze
    PORT = 6379
    DB = 0
    TRUE_VALUES = %w[1 true yes].freeze

    # e.g. "redis://:s3cr3t@redis_store:6379/0", or "redis://redis_store:6379/0" with no password.
    # With REDIS_TLS set the scheme is "rediss", as required by servers that only accept TLS
    # connections, such as AWS ElastiCache with in-transit encryption enabled.
    def self.url
      host = ENV.fetch('REDIS_HOST', DEFAULT_HOST)
      password = ENV.fetch('REDIS_PASSWORD', nil)
      auth = password.nil? || password.empty? ? '' : ":#{CGI.escape(password)}@"
      "#{scheme}://#{auth}#{host}:#{PORT}/#{DB}"
    end

    def self.scheme
      tls = ENV.fetch('REDIS_TLS', '').strip.downcase
      TRUE_VALUES.include?(tls) ? 'rediss' : 'redis'
    end
  end
end
