module Seek
  module Storage
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

    class << self
      private

      def build_adapter_for(adapter_key)
        cfg = config
        case cfg[:backend]
        when 's3'
          require 'seek/storage/s3_adapter'
          prefix = adapter_key == :dat ? 'assets' : 'converted'
          S3Adapter.new(**cfg.merge(prefix: prefix))
        else
          base = adapter_key == :dat ? Seek::Config.asset_filestore_path
                                     : Seek::Config.converted_filestore_path
          LocalAdapter.new(base_path: base)
        end
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
