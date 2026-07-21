require 'cgi'

module Seek
  # Single source of truth for the Redis connection URL, built from REDIS_HOST and (optionally)
  # REDIS_PASSWORD. The cache store, the settings cache and the session store all go through here so
  # they connect to the same server and all authenticate when a password is set - previously the
  # session store built an authenticated URL while the cache stores read a bare REDIS_URL, so a
  # password-protected Redis broke the cache while leaving sessions working.
  #
  # Loaded via require_relative from config/environments/*.rb, which are evaluated before Zeitwerk
  # autoloading is available, so this must not reference autoloaded constants or ActiveSupport core
  # extensions (hence plain Ruby rather than String#present?).
  module RedisConfig
    DEFAULT_HOST = 'localhost'.freeze
    PORT = 6379
    DB = 0

    # e.g. "redis://:s3cr3t@redis_store:6379/0", or "redis://redis_store:6379/0" with no password.
    def self.url
      host = ENV.fetch('REDIS_HOST', DEFAULT_HOST)
      password = ENV.fetch('REDIS_PASSWORD', nil)
      auth = password.nil? || password.empty? ? '' : ":#{CGI.escape(password)}@"
      "redis://#{auth}#{host}:#{PORT}/#{DB}"
    end
  end
end
