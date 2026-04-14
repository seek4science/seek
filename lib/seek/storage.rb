module Seek
  # Provides a pluggable storage backend for ContentBlob file I/O.
  # Supports local filesystem (LocalAdapter) and S3-compatible stores (S3Adapter).
  # The active backend is chosen at boot from config/seek_storage.yml.
  module Storage
    class ConfigurationError < StandardError; end

    VALID_BACKENDS    = %w[local s3].freeze
    S3_REQUIRED_KEYS  = %i[bucket access_key_id secret_access_key].freeze

    # Validates the current storage configuration without contacting any remote service.
    # Raises ConfigurationError with a human-readable message on invalid config.
    # Call from config/initializers/seek_storage.rb so misconfiguration fails at boot.
    def self.validate_config!
      validate!(config)
    end

    # Returns the adapter for the given file format.
    # 'dat' → asset_filestore_path (or S3 'assets/' prefix)
    # any other format → converted_filestore_path (or S3 'converted/' prefix)
    # Memoized at module level — at most 2 adapter instances per process.
    def self.adapter_for(format = 'dat')
      adapter_key = format == 'dat' ? :dat : :converted
      @adapters ||= {}
      @adapters[adapter_key] ||= build_adapter_for(adapter_key)
    end

    # Reset all memoized state. Call in tests that swap config or paths.
    def self.reset!
      @adapters = nil
      @config   = nil
    end

    # Returns a hash of non-sensitive configuration info safe for display in the UI.
    # Never includes access_key_id, secret_access_key, or other credentials.
    def self.status
      cfg = config
      info = { backend: cfg[:backend].to_s }
      return info unless info[:backend] == 's3'

      info[:bucket]           = cfg[:bucket]
      info[:region]           = cfg.fetch(:region, 'us-east-1')
      info[:endpoint]         = cfg[:endpoint] if cfg[:endpoint].present?
      info[:force_path_style] = cfg[:force_path_style] if cfg[:force_path_style]
      info
    end

    class << self
      private

      def validate!(cfg)
        backend = cfg[:backend].to_s
        unless VALID_BACKENDS.include?(backend)
          raise ConfigurationError,
                "Unknown storage backend '#{backend}'. Valid values: #{VALID_BACKENDS.join(', ')}. " \
                'Check config/seek_storage.yml.'
        end

        validate_s3_config!(cfg) if backend == 's3'
      end

      def validate_s3_config!(cfg)
        missing = S3_REQUIRED_KEYS.select { |k| cfg[k].blank? }
        return if missing.empty?

        raise ConfigurationError,
              "S3 storage backend is missing required configuration: #{missing.join(', ')}. " \
              'Check config/seek_storage.yml.'
      end

      def build_adapter_for(adapter_key)
        case config[:backend]
        when 's3' then build_s3_adapter(adapter_key)
        else           build_local_adapter(adapter_key)
        end
      end

      def build_s3_adapter(adapter_key)
        require 'seek/storage/s3_adapter'
        prefix = adapter_key == :dat ? 'assets' : 'converted'
        S3Adapter.new(**config.merge(prefix: prefix))
      end

      def build_local_adapter(adapter_key)
        base = if adapter_key == :dat
                 Seek::Config.asset_filestore_path
               else
                 Seek::Config.converted_filestore_path
               end
        LocalAdapter.new(base_path: base)
      end

      def config
        @config ||= load_config
      end

      def load_config
        path = Rails.root.join('config', 'seek_storage.yml')
        return { backend: 'local' } unless path.exist?

        raw = YAML.safe_load(
          ERB.new(File.read(path)).result,
          aliases: true
        )
        (raw[Rails.env] || raw['default'] || {}).symbolize_keys
      end
    end
  end
end
