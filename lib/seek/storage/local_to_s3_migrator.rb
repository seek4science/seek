require 'seek/storage/local_adapter'
require 'seek/storage/s3_adapter'

module Seek
  module Storage
    # Copies ContentBlob files (originals + persisted derivatives) from the local
    # filesystem to the configured S3 backend.
    #
    # Usage:
    #   migrator = Seek::Storage::LocalToS3Migrator.new(dry_run: true)
    #   result   = migrator.run
    #   puts result.summary
    #
    # The task is idempotent: objects that already exist on S3 with a matching
    # size are silently skipped. A size mismatch is treated as an error (the
    # destination is never silently overwritten).
    #
    # Local source files are never deleted or modified.
    class LocalToS3Migrator
      DERIVATIVE_FORMATS = %w[pdf txt].freeze

      Result = Struct.new(:copied, :skipped, :missing, :failed, keyword_init: true) do
        def summary
          "Copied: #{copied}  Skipped: #{skipped}  Missing: #{missing}  Failed: #{failed}"
        end
      end

      # Pass explicit adapters only in tests. Production always builds from config.
      def initialize(dry_run: false, output: $stdout, **adapters)
        @dry_run = dry_run
        @output  = output
        assign_adapters(adapters)
      end

      # Iterates blobs from +scope+ (defaults to all ContentBlob records).
      # Pass a custom scope in tests to avoid touching the database.
      def run(scope: ContentBlob)
        counts = { copied: 0, skipped: 0, missing: 0, failed: 0 }
        scope.find_each { |blob| migrate_blob(blob, counts) }
        Result.new(**counts)
      end

      private

      def assign_adapters(adapters)
        if adapters.key?(:local_dat)
          @local_dat  = adapters[:local_dat]
          @local_conv = adapters[:local_conv]
          @s3_dat     = adapters[:s3_dat]
          @s3_conv    = adapters[:s3_conv]
        else
          build_adapters_from_config
        end
      end

      def build_adapters_from_config
        cfg = Seek::Storage.send(:config)
        raise ConfigurationError, 'S3 backend is not configured. Set backend: s3 in seek_storage.yml.' \
          unless cfg[:backend].to_s == 's3'

        @local_dat  = LocalAdapter.new(base_path: Seek::Config.asset_filestore_path)
        @local_conv = LocalAdapter.new(base_path: Seek::Config.converted_filestore_path)
        @s3_dat     = S3Adapter.new(**cfg.merge(prefix: 'assets'))
        @s3_conv    = S3Adapter.new(**cfg.merge(prefix: 'converted'))
      end

      def migrate_blob(blob, counts)
        return unless blob.uuid.present?

        migrate_file(blob.storage_key, @local_dat, @s3_dat, counts)

        DERIVATIVE_FORMATS.each do |fmt|
          key = blob.storage_key(fmt)
          migrate_file(key, @local_conv, @s3_conv, counts) if @local_conv.exist?(key)
        end
      end

      def migrate_file(key, src, dest, counts)
        unless src.exist?(key)
          log "  MISSING  #{key}"
          counts[:missing] += 1
          return
        end

        local_size = File.size(src.full_path(key))
        check_existing(key, dest, local_size, counts) || upload(key, src, dest, local_size, counts)
      rescue StandardError => e
        log "  ERROR    #{key} (#{e.message})"
        counts[:failed] += 1
      end

      def check_existing(key, dest, local_size, counts)
        return false unless dest.exist?(key)

        if dest.size(key) == local_size
          log "  SKIP     #{key} (already on S3, size matches)"
          counts[:skipped] += 1
        else
          log "  ERROR    #{key} (exists on S3 but size mismatch: local=#{local_size} remote=#{dest.size(key)})"
          counts[:failed] += 1
        end
        true
      end

      def upload(key, src, dest, local_size, counts)
        if @dry_run
          log "  DRY-RUN  #{key} (#{local_size} bytes)"
          counts[:copied] += 1
          return
        end

        dest.copy_from_path(src.full_path(key), key)
        verify_upload(key, dest, local_size, counts)
      end

      def verify_upload(key, dest, local_size, counts)
        uploaded_size = dest.size(key)
        if uploaded_size == local_size
          log "  COPIED   #{key} (#{local_size} bytes)"
          counts[:copied] += 1
        else
          log "  ERROR    #{key} (uploaded size #{uploaded_size} != local #{local_size})"
          counts[:failed] += 1
        end
      end

      def log(msg)
        @output.puts msg
      end
    end
  end
end
