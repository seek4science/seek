module Seek
  module Storage
    # Copies existing Avatar and ModelImage master images from their local fleximage
    # directories to the configured S3 backend.
    #
    # Needed because avatars/model images are adapter-backed (Seek::FleximageAdapterStorage) but are
    # NOT ContentBlobs, so the ContentBlob-based LocalToS3Migrator does not cover them. New uploads
    # already go straight to S3; this task is only for images created before adapter-backed storage.
    #
    # Usage:
    #   migrator = Seek::Storage::FleximageToS3Migrator.new(dry_run: true)
    #   result   = migrator.run
    #   puts result.summary
    #
    # Idempotent: objects already on S3 with a matching size are skipped; a size mismatch is treated
    # as an error (the destination is never silently overwritten). Local source files are never deleted.
    class FleximageToS3Migrator
      MIGRATABLE_MODELS = [Avatar, ModelImage].freeze

      Result = Struct.new(:copied, :skipped, :missing, :failed, keyword_init: true) do
        def summary
          "Copied: #{copied}  Skipped: #{skipped}  Missing: #{missing}  Failed: #{failed}"
        end
      end

      def initialize(dry_run: false, output: $stdout)
        @dry_run = dry_run
        @output  = output
      end

      # Iterates the given models (defaults to Avatar + ModelImage). Each record exposes its own
      # storage_adapter/storage_key via Seek::FleximageAdapterStorage, so no adapters are injected —
      # tests route through the adapter using the standard S3 stub helper. The caller (rake task) is
      # responsible for ensuring the S3 backend is configured before running.
      def run(models: MIGRATABLE_MODELS)
        counts = { copied: 0, skipped: 0, missing: 0, failed: 0 }
        models.each do |klass|
          klass.find_each { |record| migrate_record(record, counts) }
        end
        Result.new(**counts)
      end

      private

      def migrate_record(record, counts)
        key        = record.storage_key
        local_path = record.file_path
        dest       = record.storage_adapter

        unless local_path && File.exist?(local_path)
          log "  MISSING  #{label(record)} #{key}"
          counts[:missing] += 1
          return
        end

        local_size = File.size(local_path)
        check_existing(record, key, dest, local_size, counts) ||
          upload(record, key, local_path, dest, local_size, counts)
      rescue StandardError => e
        log "  ERROR    #{label(record)} (#{e.message})"
        counts[:failed] += 1
      end

      def check_existing(record, key, dest, local_size, counts)
        return false unless dest.exist?(key)

        if dest.size(key) == local_size
          log "  SKIP     #{label(record)} #{key} (already on S3, size matches)"
          counts[:skipped] += 1
        else
          log "  ERROR    #{label(record)} #{key} (exists on S3 but size mismatch: " \
              "local=#{local_size} remote=#{dest.size(key)})"
          counts[:failed] += 1
        end
        true
      end

      def upload(record, key, local_path, dest, local_size, counts)
        if @dry_run
          log "  DRY-RUN  #{label(record)} #{key} (#{local_size} bytes)"
          counts[:copied] += 1
          return
        end

        dest.copy_from_path(local_path, key)
        verify_upload(record, key, dest, local_size, counts)
      end

      def verify_upload(record, key, dest, local_size, counts)
        uploaded_size = dest.size(key)
        if uploaded_size == local_size
          log "  COPIED   #{label(record)} #{key} (#{local_size} bytes)"
          counts[:copied] += 1
        else
          log "  ERROR    #{label(record)} #{key} (uploaded size #{uploaded_size} != local #{local_size})"
          counts[:failed] += 1
        end
      end

      def label(record)
        "#{record.class.name}##{record.id}"
      end

      def log(msg)
        @output.puts msg
      end
    end
  end
end
